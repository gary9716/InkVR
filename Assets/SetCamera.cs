using UnityEngine;
using System.Collections;

public class SetCamera : MonoBehaviour {

    //public float size = 4;

    Camera cam;

	// Use this for initialization
	void Start () {
        cam = GetComponent<Camera>();
        cam.aspect = 1920.0f/1200;
        cam.orthographic = true;
        GetComponent<AudioListener>().enabled = false;
    }

    // Update is called once per frame
    /*
    void Update () {
        cam.orthographicSize = size;
	}
    */
}
