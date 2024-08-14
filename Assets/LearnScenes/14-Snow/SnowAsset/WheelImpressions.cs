using UnityEngine;

public class WheelImpressions : MonoBehaviour
{
    public Shader _shader;
    public GameObject _terrain;
    public Transform[] _wheels;

    [Range(0, 2)] public float _bSize;

    [Range(0, 1)] public float _bStrength;

    private Material _draw;
    private RenderTexture _heightMap;
    private RaycastHit _hit;
    private int _mask;

    private Material _snow;

    // Use this for initialization
    private void Start()
    {
        _mask = LayerMask.GetMask("Ground");

        _draw = new Material(_shader);
        _snow = _terrain.GetComponent<MeshRenderer>().material; // tesselation shader
        _heightMap = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGBFloat);
        _snow.SetTexture("_HeightMap", _heightMap);
    }

    // Update is called once per frame
    private void Update()
    {
        for (var i = 0; i < _wheels.Length; i++)
        {
            // raycasting towards mesh
            if (!Physics.Raycast(_wheels[i].position, -Vector3.up, out _hit, 1f, _mask)) continue;

            Debug.Log(_hit.transform.position);

            _draw.SetVector("_Coordinates", new Vector4(_hit.textureCoord.x, _hit.textureCoord.y, 0, 0));
            _draw.SetFloat("_Strength", _bStrength);
            _draw.SetFloat("_Size", _bSize);
            var tmp = RenderTexture.GetTemporary(_heightMap.width, _heightMap.height, 0, RenderTextureFormat.ARGBFloat);
            Graphics.Blit(_heightMap, tmp);
            Graphics.Blit(tmp, _heightMap, _draw);
            RenderTexture.ReleaseTemporary(tmp);
        }
    }
}