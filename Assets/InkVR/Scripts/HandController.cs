using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class HandController : MonoBehaviour {

    public Transform ctrlRoot;
    public Transform handOpenedState;
    public Transform handClosedState;

    float currentFactor = 0;
    public float ctrlFactor;

    public class HandCtrlNode
    {
        public Transform ctrlTrans;
        public Transform openTrans;
        public Transform closeTrans;
    }
    
    public List<HandCtrlNode> ctrlNodes;

	// Use this for initialization
	void Start () {
        ctrlNodes = new List<HandCtrlNode>();
        
        if (ctrlRoot != null)
            collectNodes(ctrlRoot, FindTransform(handOpenedState, ctrlRoot.name), FindTransform(handClosedState, ctrlRoot.name));
        else
            collectNodes(transform, handOpenedState, handClosedState);
    }
	
	// Update is called once per frame
	void Update () {
        adjustEveryNode();
	}

    void adjustEveryNode()
    {
        currentFactor = Mathf.Lerp(currentFactor, ctrlFactor, 0.3f);
        foreach (HandCtrlNode node in ctrlNodes)
        {
            node.ctrlTrans.rotation = Quaternion.Slerp(node.openTrans.rotation, node.closeTrans.rotation, currentFactor);
        }
    }

    public void collectNodes(Transform parent, Transform openState, Transform closeState)
    {
        foreach (Transform t in parent) {
            if (t != null) {
                HandCtrlNode node = new HandCtrlNode();
                node.ctrlTrans = t;
                node.openTrans = openState.Find(t.name);
                node.closeTrans = closeState.Find(t.name);
                ctrlNodes.Add(node);
                collectNodes(t, node.openTrans, node.closeTrans);
            }
        }
    }

    public Transform FindTransform(Transform parent, string name)
    {
        if (parent.name.Equals(name)) return parent;
        foreach (Transform child in parent)
        {
            Transform result = FindTransform(child, name);
            if (result != null) return result;
        }
        return null;
    }
}
