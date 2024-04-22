using UnityEngine;

public class RainbowColour : MonoBehaviour
{
	private Material material;

	private Renderer rend;

	private void Start()
	{
		rend = GetComponent<Renderer>();
		material = rend.material;
		material.SetColor("_Colour", Color.magenta);
	}

	private void Update()
	{
	}
}