using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class WaypointsManager : MonoBehaviour {

    Transform[] waypoints;

	// Use this for initialization
	void Start () {
        waypoints = new Transform[transform.childCount];
        int index = 0;
        foreach (Transform t in transform)
        {
            waypoints[index] = t;
            index++;
        }
    }

    public Transform getNextWayPt()
    {
        if (waypoints != null && waypoints.Length > 0)
        {
            int index = Random.Range(0, waypoints.Length);
            Debug.Log("index:" + index);
            if(index == waypoints.Length)
            {
                index--;
            }
            return waypoints[index];
        }
        else
        {
            return null;
        }
    }
    
}
