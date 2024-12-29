using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
#if UNITY_EDITOR
using UnityEditor;
#endif

public class GrabDepthRF : ScriptableRendererFeature
{
    public RenderPassEvent m_RenderEvent = RenderPassEvent.AfterRenderingTransparents;

    private GrabDepthPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new GrabDepthPass();
        m_ScriptablePass.OnCreate();
        m_ScriptablePass.renderPassEvent = m_RenderEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!ShouldRender(renderingData)) return;
        renderer.EnqueuePass(m_ScriptablePass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (!ShouldRender(renderingData)) return;
        m_ScriptablePass.Setup(renderer.cameraDepthTargetHandle);
    }

    private bool ShouldRender(in RenderingData data)
    {
        if (data.cameraData.cameraType != CameraType.Game) return false;
        return true;
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        m_ScriptablePass.OnDispose();
    }
}


public class GrabDepthPass : ScriptableRenderPass
{
    private RTHandle _cameraDepth;
    private RTHandle _GrabDepthTex;
    private Material m_Mat;
    private readonly ProfilingSampler m_Sampler = new("GrabDepthPass");

    public void OnCreate()
    {
        m_Mat = CoreUtils.CreateEngineMaterial("Hidden/Universal Render Pipeline/CopyDepth");
    }

    public void Setup(RTHandle cameraDepth)
    {
        _cameraDepth = cameraDepth;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        var desc = renderingData.cameraData.cameraTargetDescriptor;

        Debug.Log($"当前相机的AAlevel = {desc.msaaSamples}");

        //如果要Blit深度,这些设置很重要
        desc.depthBufferBits = 32;
        desc.colorFormat = RenderTextureFormat.Depth;
        desc.msaaSamples = 1;
        desc.bindMS = false;


        RenderingUtils.ReAllocateIfNeeded(ref _GrabDepthTex, desc);
        cmd.SetGlobalTexture("_MyDepthTex", _GrabDepthTex.nameID);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get("GrabDepthPass");
        using (new ProfilingScope(cmd, m_Sampler))
        {
            //可以根据当前相机的AAlevel配置关键字
            m_Mat.EnableKeyword("_DEPTH_MSAA_2");
            m_Mat.DisableKeyword("_DEPTH_MSAA_4");
            m_Mat.DisableKeyword("_DEPTH_MSAA_8");
            m_Mat.EnableKeyword("_OUTPUT_DEPTH");
            Blitter.BlitCameraTexture(cmd, _cameraDepth, _GrabDepthTex, m_Mat, 0);
        }

        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();
        cmd.Dispose();
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }

    public void OnDispose()
    {
#if UNITY_EDITOR
        if (EditorApplication.isPlaying)
        {
            if (m_Mat != null) Object.Destroy(m_Mat);
        }
        else
        {
            if (m_Mat != null) Object.DestroyImmediate(m_Mat);
        }
#else
        if(m_Mat!=null) Object.Destroy(m_Mat);
#endif
    }
}