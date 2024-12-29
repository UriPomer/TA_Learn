using System;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BlurRenderPass : ScriptableRenderPass
{
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        throw new NotImplementedException();
    }

    // public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
    // {
    // }
}