using UnityEngine;
using System.Collections;

public class GhostItem : MonoBehaviour {

    //持续时间
    public float duration;
    //销毁时间
    public float deleteTime;

    public MeshRenderer meshRenderer;

    void Update()
    {
        float tempTime = deleteTime - Time.time;
        if (tempTime <= 0)
        {//到时间就销毁
            GameObject.Destroy(this.gameObject);
        }
        else if (meshRenderer.material)
        {
            meshRenderer.material.SetInt("_Pow", meshRenderer.material.GetInt("_Pow") + 1);
        }

    }
}
