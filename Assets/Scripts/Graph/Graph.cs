using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Graph : MonoBehaviour
{
	[SerializeField] private Transform pointPrefab;
	[SerializeField] [Range(10, 200)] private int resolution = 10;
	[SerializeField] private FunctionLibrary.FunctionName function;
	private Transform[] points;

	[SerializeField] [Min(0f)] private float functionDuration = 1f, transitionDuration = 1f;
	private float duration;

	private bool transitioning;
	private FunctionLibrary.FunctionName transitionFunction;

	public enum TransitionMode
	{
		Cycle,
		Random
	}

	[SerializeField] private TransitionMode transitionMode;


	private void Awake()
	{
		var step = 2f / resolution;
		var scale = Vector3.one * step;
		points = new Transform[resolution * resolution];
		for (var i = 0; i < points.Length; i++)
		{
			var point = points[i] = Instantiate(pointPrefab);
			point.localScale = scale;
			point.SetParent(transform, false);
		}
	}

	private void Start()
	{
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

		if (transitioning)
			UpdateFunctionTransition();
		else
			UpdateFunction();
	}

	private void UpdateFunction()
	{
		var f = FunctionLibrary.GetFunction(function);
		var time = Time.time;
		var step = 2f / resolution;
		var v = 0.5f * step - 1f;
		for (int i = 0, x = 0, z = 0; i < points.Length; i++, x++)
		{
			if (x == resolution)
			{
				x = 0;
				z += 1;
				v = (z + 0.5f) * step - 1f;
			}

			var u = (x + 0.5f) * step - 1f;

			points[i].localPosition = f(u, v, time);
		}
	}

	private void UpdateFunctionTransition()
	{
		FunctionLibrary.Function
			from = FunctionLibrary.GetFunction(transitionFunction),
			to = FunctionLibrary.GetFunction(function);
		var progress = duration / transitionDuration;
		var time = Time.time;
		var step = 2f / resolution;
		var v = 0.5f * step - 1f;
		for (int i = 0, x = 0, z = 0; i < points.Length; i++, x++)
		{
			if (x == resolution)
			{
				x = 0;
				z += 1;
				v = (z + 0.5f) * step - 1f;
			}

			var u = (x + 0.5f) * step - 1f;

			points[i].localPosition = FunctionLibrary.Morph(
				u, v, time, from, to, progress
			);
		}
	}

	private void PickNextFunction()
	{
		function = transitionMode == TransitionMode.Cycle
			? FunctionLibrary.GetNextFunctionName(function)
			: FunctionLibrary.GetRandomFunctionNameOtherThan(function);
	}
}