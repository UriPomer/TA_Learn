using UnityEngine;

public class FrameCounter : MonoBehaviour
{
    private Material _material; // 着色器材质
    private int _frameCount = 0; // 帧计数器

    void Start()
    {
        _material = GetComponent<Renderer>().material; // 获取材质
    }

    void Update()
    {
        _frameCount++;
        _material.SetInt("_iFrame", _frameCount); // 将帧数设置为材质的属性
    }
}