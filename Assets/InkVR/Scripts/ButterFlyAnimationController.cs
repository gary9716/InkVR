using UnityEngine;
using System.Collections;

public class ButterFlyAnimationController : MonoBehaviour {

    Animator animator;
    string flyingStateName = "Flying";
    string takeOffTriggerName = "TakeOff";
    string idleTriggerName = "toIdle";

    // Use this for initialization
    void Awake()
    {
        animator = GetComponent<Animator>();
    }

    public void takeOff()
    {
        animator.SetBool(flyingStateName, true);
        animator.SetTrigger(takeOffTriggerName);
    }

    public void land()
    {
        animator.SetBool(flyingStateName, false);
    }

    public void idle()
    {
        animator.SetTrigger(idleTriggerName);
    }

    public void stopIdling()
    {
        animator.SetBool(idleTriggerName, false);
    }

    public bool isPrepareToIdle()
    {
        return animator.GetBool(idleTriggerName);
    }

    public bool isFlying()
    {
        return animator.GetBool(flyingStateName);
    }



}