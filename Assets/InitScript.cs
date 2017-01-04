using UnityEngine;
using System.Collections;
using VRTK;
public class InitScript : MonoBehaviour {

    public VRTK_HeightAdjustTeleport teleport;

	// Use this for initialization
	void Start () {
        Invoke("disableFeature", 5);
	}

    void disableFeature()
    {
        teleport.playSpaceFalling = false;
    }
	
}
