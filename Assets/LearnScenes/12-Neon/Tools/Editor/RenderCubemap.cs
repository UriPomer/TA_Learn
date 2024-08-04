using System.IO;
using UnityEditor;
using UnityEngine;

public class RenderCubemap : EditorWindow
{
    public enum GenMode
    {
        SingleCubemap = 0,
        SixTextures
    }


    private static readonly string[] _names = { "16", "32", "64", "128", "256", "512", "1024", "2048" };
    private static readonly int[] _sizes = { 16, 32, 64, 128, 256, 512, 1024, 2048 };

    private static readonly Vector3[] _cameraAngles =
    {
        new(0, 90, 0), new(0, -90, 0),
        new(-90, 0, 0), new(90, 0, 0),
        new(0, 0, 0), new(0, 180, 0)
    };

    private static readonly string[] _filePostfixs =
    {
        "_Left", "_Right", "_Up", "_Down", "_Front", "_Back"
    };

    [SerializeField] private LayerMask _layerMask = -1;

    private Transform _center;
    private Texture2D[] _colorTexs;

    private GenMode _genMode;
    private int _lastSelectedSize;
    private RenderTexture[] _rtexs;
    private int _selectedSize = 1024;
    private SerializedObject serializedObject;

    private void OnEnable()
    {
        titleContent = new GUIContent("RenderCubemap");
        serializedObject = new SerializedObject(this);
    }

    private void OnDestroy()
    {
        DestroyResources();
    }


    private void OnGUI()
    {
        GUILayout.Space(5);

        EditorGUI.BeginChangeCheck();
        _genMode = (GenMode)EditorGUILayout.EnumPopup("Mode", _genMode);
        _selectedSize = EditorGUILayout.IntPopup("Face Size", _selectedSize, _names, _sizes);
        _center = EditorGUILayout.ObjectField("Center", _center, typeof(Transform), true) as Transform;
        EditorGUILayout.PropertyField(serializedObject.FindProperty("_layerMask"));

        GUILayout.Space(15);

        var hasError = false;
        var oldContentColor = GUI.contentColor;
        GUI.contentColor = Color.red;
        if (_center == null)
        {
            GUILayout.Label("必须设置'Center'!");
            hasError = true;
        }

        var mainCam = Camera.main;
        if (mainCam == null)
        {
            GUI.contentColor = Color.red;
            GUILayout.Label("场景中必须有Main Camera!");
            hasError = true;
        }

        GUI.contentColor = oldContentColor;

        if (hasError) return;


        // _layerMask = EditorToolUtility.LayerMaskField("Culling Mask", _layerMask);
        GUILayout.Space(15);

        EditorGUILayout.BeginHorizontal();
        GUILayout.FlexibleSpace();
        if (GUILayout.Button("Bake", GUILayout.Width(100)))
        {
            if (_rtexs == null || _selectedSize != _lastSelectedSize)
            {
                DestroyResources();
                CreateResources();
                _lastSelectedSize = _selectedSize;
            }


            var go = Instantiate(mainCam.gameObject);
            go.name = "__CubemapCamera__";
            var cam = go.GetComponent<Camera>();
            cam.enabled = false;
            cam.backgroundColor = Camera.main.backgroundColor;
            cam.aspect = 1;
            cam.fieldOfView = 90;
            cam.cullingMask = _layerMask;

            go.transform.position = _center.position;

            var oldRt = RenderTexture.active;
            for (var i = 0; i < 6; i++)
            {
                go.transform.localEulerAngles = _cameraAngles[i];

                RenderTexture.active = _rtexs[i];
                cam.targetTexture = _rtexs[i];
                cam.Render();

                _colorTexs[i].ReadPixels(new Rect(0, 0, _selectedSize, _selectedSize), 0, 0);
                _colorTexs[i].Apply();
            }


            RenderTexture.active = oldRt;
            DestroyImmediate(go);

            var tex = WriteAndImportTexture();
            if (tex != null)
                Debug.Log("渲染到环境贴图完成！", tex);
        }

        EditorGUILayout.EndHorizontal();
    }

    private void CreateResources()
    {
        _rtexs = new RenderTexture[6];
        for (var i = 0; i < 6; i++)
        {
            _rtexs[i] = new RenderTexture(_selectedSize, _selectedSize, 24);
            _rtexs[i].hideFlags = HideFlags.HideAndDontSave;
        }

        _colorTexs = new Texture2D[6];
        for (var i = 0; i < 6; i++)
            _colorTexs[i] = new Texture2D(_selectedSize, _selectedSize, TextureFormat.RGB24, false);
    }

    private void DestroyResources()
    {
        if (_rtexs != null)
        {
            for (var i = 0; i < 6; i++)
                DestroyImmediate(_rtexs[i]);
            _rtexs = null;
        }

        if (_colorTexs != null)
            for (var i = 0; i < 6; i++)
                DestroyImmediate(_colorTexs[i]);
    }

    private Texture2D WriteAndImportTexture()
    {
        if (_genMode == GenMode.SingleCubemap)
        {
            var path = EditorUtility.SaveFilePanelInProject("Save Cubemap", "", "png",
                "Please enter a file name to save cubemap to");
            if (!string.IsNullOrEmpty(path))
            {
                var cubeTex = new Texture2D(_selectedSize * 4, _selectedSize * 3, TextureFormat.RGB24, false);

                var colors = _colorTexs[0].GetPixels();
                cubeTex.SetPixels(_selectedSize * 2, _selectedSize, _selectedSize, _selectedSize, colors);
                colors = _colorTexs[1].GetPixels();
                cubeTex.SetPixels(0, _selectedSize, _selectedSize, _selectedSize, colors);
                colors = _colorTexs[2].GetPixels();
                cubeTex.SetPixels(_selectedSize, _selectedSize * 2, _selectedSize, _selectedSize, colors);
                colors = _colorTexs[3].GetPixels();
                cubeTex.SetPixels(_selectedSize, 0, _selectedSize, _selectedSize, colors);
                colors = _colorTexs[4].GetPixels();
                cubeTex.SetPixels(_selectedSize, _selectedSize, _selectedSize, _selectedSize, colors);
                colors = _colorTexs[5].GetPixels();
                cubeTex.SetPixels(_selectedSize * 3, _selectedSize, _selectedSize, _selectedSize, colors);

                cubeTex.Apply();
                var bytes = cubeTex.EncodeToPNG();
                File.WriteAllBytes(path, bytes);
                AssetDatabase.ImportAsset(path);
                var importer = AssetImporter.GetAtPath(path) as TextureImporter;
                importer.textureType = TextureImporterType.Default;
                importer.textureShape = TextureImporterShape.TextureCube;
                importer.generateCubemap = TextureImporterGenerateCubemap.AutoCubemap;
                importer.maxTextureSize = _selectedSize;
                AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceUpdate);
                cubeTex = AssetDatabase.LoadAssetAtPath(path, typeof(Texture2D)) as Texture2D;

                return cubeTex;
            }

            return null;
        }

        if (_genMode == GenMode.SixTextures)
        {
            var path = EditorUtility.SaveFilePanelInProject("Save Textures", "", "png",
                "Please enter a file name to save textures to");
            if (!string.IsNullOrEmpty(path))
            {
                //Material material = new Material(Shader.Find("Skybox/6 Sided"));
                //AssetDatabase.CreateAsset(material, path);

                var header = path.Substring(0, path.Length - 4);
                for (var i = 0; i < 6; i++)
                    if (header.EndsWith(_filePostfixs[i]))
                    {
                        header = header.Substring(0, header.Length - _filePostfixs[i].Length);
                        break;
                    }

                var newTextures = new Texture2D[6];
                for (var i = 0; i < 6; i++)
                {
                    var outPath = header + _filePostfixs[i] + ".png";

                    var bytes = _colorTexs[i].EncodeToPNG();
                    File.WriteAllBytes(outPath, bytes);

                    AssetDatabase.ImportAsset(outPath);
                    var importer = AssetImporter.GetAtPath(outPath) as TextureImporter;
                    importer.textureType = TextureImporterType.Default;
                    importer.wrapMode = TextureWrapMode.Clamp;
                    importer.maxTextureSize = _selectedSize;
                    AssetDatabase.ImportAsset(outPath, ImportAssetOptions.ForceUpdate);

                    newTextures[i] = AssetDatabase.LoadAssetAtPath(outPath, typeof(Texture2D)) as Texture2D;
                }

                return newTextures[0];
            }
        }

        return null;
    }


    [MenuItem("美术/渲染到环境贴图...", false, 5000)]
    private static void Init()
    {
        var editWindow = CreateInstance<RenderCubemap>();
        editWindow.Show();
    }
}