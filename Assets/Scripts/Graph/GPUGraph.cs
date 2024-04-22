using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GPUGraph : MonoBehaviour
{
	[SerializeField] [Range(10, 1000)] private int resolution = 10;
	[SerializeField] private FunctionLibrary.FunctionName function;
	[SerializeField] [Min(0f)] private float functionDuration = 1f, transitionDuration = 1f;
	private float duration;
	private bool transitioning;
	private FunctionLibrary.FunctionName transitionFunction;
	private ComputeBuffer positionsBuffer;

	private static readonly int
		positionsId = Shader.PropertyToID("_Positions"),
		resolutionId = Shader.PropertyToID("_Resolution"),
		stepId = Shader.PropertyToID("_Step"),
		timeId = Shader.PropertyToID("_Time"),
		transitionProgressId = Shader.PropertyToID("_TransitionProgress");

	private const int maxResolution = 1000;

	public enum TransitionMode
	{
		Cycle,
		Random
	}

	[SerializeField] private TransitionMode transitionMode = TransitionMode.Cycle;

	[SerializeField] private ComputeShader computeShader;

	[SerializeField] private Material material;

	[SerializeField] private Mesh mesh;

	private void OnEnable()
	{
		positionsBuffer = new ComputeBuffer(maxResolution * maxResolution, 3 * 4);
	}

	private void OnDisable()
	{
		positionsBuffer.Release();
		positionsBuffer = null;
	}

	private void Update()
	{
		duration += Time.deltaTime;
		if (transitioning)
		{
			if (duration >= transitionDuration)
			{
				duration -= transitionDuration;
				transitioning = false;
			}
		}
		else if (duration >= functionDuration)
		{
			duration -= functionDuration;
			transitioning = true;
			transitionFunction = function;
			PickNextFunction();
		}

		UpdateFunctionOnGPU();
	}

	private void UpdateFunctionOnGPU()
	{
		var step = 2f / resolution;

		computeShader.SetInt(resolutionId, resolution);
		computeShader.SetFloat(stepId, step);
		computeShader.SetFloat(timeId, Time.time);
		if (transitioning)
			computeShader.SetFloat(transitionProgressId, Mathf.SmoothStep(0f, 1f, duration / transitionDuration));
		var kernelIndex = (int)function +
		                  (int)(transitioning ? transitionFunction : function) * FunctionLibrary.FunctionCount;
		computeShader.SetBuffer(kernelIndex, positionsId, positionsBuffer);

		var groups = Mathf.CeilToInt(resolution / 8f);
		computeShader.Dispatch(kernelIndex, groups, groups, 1);


		material.SetFloat(stepId, step);
		material.SetBuffer(positionsId, positionsBuffer);
		var bounds = new Bounds(Vector3.zero, Vector3.one * (2f + 2f / resolution));
		Graphics.DrawMeshInstancedProcedural(mesh, 0, material, bounds, resolution * resolution);
	}


	private void PickNextFunction()
	{
		function = transitionMode == TransitionMode.Cycle
			? FunctionLibrary.GetNextFunctionName(function)
			: FunctionLibrary.GetRandomFunctionNameOtherThan(function);
	}
}