using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class GrabColorRF : ScriptableRendererFeature
{
    public RenderPassEvent m_RenderEvent = RenderPassEvent.AfterRenderingTransparents;
    private GrabColorPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new GrabColorPass();
        m_ScriptablePass.renderPassEvent = m_RenderEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!ShouldExecute(renderingData)) return;
        renderer.EnqueuePass(m_ScriptablePass);
    }

    public override void SetupRenderPasses(ScriptableRenderer renderer, in RenderingData renderingData)
    {
        if (!ShouldExecute(renderingData)) return;
        m_ScriptablePass.Setup(renderer.cameraColorTargetHandle);
    }

    private bool ShouldExecute(in RenderingData data)
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


public class GrabColorPass : ScriptableRenderPass
{
    private RTHandle _cameraColor;
    private RTHandle _GrabTex;
    private readonly ProfilingSampler m_Sampler = new("GrabColorPass");

    public void Setup(RTHandle cameraColor)
    {
        _cameraColor = cameraColor;
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        var desc = renderingData.cameraData.cameraTargetDescriptor;
        desc.depthBufferBits = 0; //这步很重要,不然无法blit颜色
        RenderingUtils.ReAllocateIfNeeded(ref _GrabTex, desc);
        cmd.SetGlobalTexture("_MyColorTex", _GrabTex.nameID);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get("GrabColorPass");
        using (new ProfilingScope(cmd, m_Sampler))
        {
            Blitter.BlitCameraTexture(cmd, _cameraColor, _GrabTex);
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
        _GrabTex?.Release();
    }
}