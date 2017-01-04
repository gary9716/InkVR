using UnityEngine;
using System.Collections;

public class FogManager : MonoBehaviour {

    public FogVolume[] fogVs;

	// Use this for initialization
	void Start () {
        Camera[] camArray = Camera.allCameras;
        foreach(FogVolume fogV in fogVs)
        {
            foreach(Camera cam in camArray)
            {
                fogV.setCamDepth(cam);
            }
        }    
	}
	
}
