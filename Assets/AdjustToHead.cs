using UnityEngine;
using System.Collections;

public class AdjustToHead : MonoBehaviour {

    public GameObject refObj;

    float planeLen = 10;

	// Use this for initialization
	void Start () {
	    
	}
	
	// Update is called once per frame
	void Update () {
	    if(refObj!= null)
        {
            Vector3 pos = refObj.transform.position;
            pos.x -= (((refObj.transform.localScale.x/2) + (transform.localScale.x/2)) * planeLen);
            transform.position = pos;
        }
	}
}
