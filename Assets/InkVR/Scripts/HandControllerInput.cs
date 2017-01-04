using UnityEngine;
using System.Collections;
using VRTK;

public class HandControllerInput : MonoBehaviour {

    public VRTK_ControllerEvents controllerEvents;
    public HandController handController;

	// Use this for initialization
	void Start () {
        controllerEvents.TriggerAxisChanged += triggerAxisChanged;
        handController = GetComponent<HandController>();
    }
	
    void triggerAxisChanged(object sender, ControllerInteractionEventArgs e)
    {
        handController.ctrlFactor = e.buttonPressure;
    }
}
