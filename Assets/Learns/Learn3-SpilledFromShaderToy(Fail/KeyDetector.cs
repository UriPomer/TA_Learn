using UnityEngine;

public class KeyDetector : MonoBehaviour
{
    private Material material;

    private void Start()
    {
        material = GetComponent<Renderer>().material;
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.I)) // 当 I 键被按下
            material.SetFloat("_KEY_I", 1); // 将材质中的 _KeyI 属性设置为 1
        else if (Input.GetKeyUp(KeyCode.I)) // 当 I 键被释放
            material.SetFloat("_KEY_I", 0); // 将材质中的 _KeyI 属性设置为 0
    }
}