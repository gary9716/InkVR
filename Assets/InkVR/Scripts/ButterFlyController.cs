using UnityEngine;
using System.Collections;
using DG.Tweening;

public class ButterFlyController : MonoBehaviour {

    public Transform selfObj;
    public Transform target;
    Rigidbody rigid;
    ButterFlyAnimationController bfAnimController;
    float turningFactor = 0.6f;
    //float movingSpeed = 1f;
    float landingDist = 1f;

    float step = 0.3f;
    float movingDuration = 0.1f;
    float turningDuration = 0.1f;

    public SphereCollider myCollider;
    public WaypointsManager wayPtsManager;
    float staticRadius = 1.3f;
    float flyingRadius = 2.2f;
    int castLayerMask;
    int handLayerIndex;
    Sequence currentSeq;
    Vector3 avoidDir = Vector3.zero;
    int landingSpotsLayer;
    const int subseqCycle = 3;
    int randSubseqCount = subseqCycle;
    bool isTakingOff = false;

    public bool testFly;

    // Use this for initialization
    void Start () {
        myCollider.radius = staticRadius;
        bfAnimController = GetComponent<ButterFlyAnimationController>();
        rigid = GetComponent<Rigidbody>();
        landingSpotsLayer = LayerMask.NameToLayer("landingSpots");
        handLayerIndex = LayerMask.NameToLayer("Hands");
        castLayerMask = ~(1 << landingSpotsLayer);
        bfAnimController.idle();

        if (testFly)
            Invoke("chooseTargetAndTakeOff", 3);

    }

    // Update is called once per frame
    void Update() {
        //random Idle behaviour
        if(!bfAnimController.isFlying() && !bfAnimController.isPrepareToIdle())
        {
            if (Random.Range(0, 10000) > 9900)
            {
                if (randSubseqCount == 0) {
                    randSubseqCount = subseqCycle;
                    bfAnimController.idle();
                }

                randSubseqCount--;
            }
        }

        if(bfAnimController.isFlying())
            myCollider.radius = flyingRadius;
        else
            myCollider.radius = staticRadius;

        //if (!bfAnimController.isFlying())
        //{
        //    chooseTargetAndTakeOff();
        //}

    }

    public void takeOff() {
        bfAnimController.stopIdling();
        bfAnimController.takeOff();
        Invoke("flyToTarget", 1.7f);
        isTakingOff = false;
    }


    public void flyToTarget() {
        Vector3 targetDir = (target.position - selfObj.position);
        if (targetDir.magnitude < landingDist)
        {
            if(target.gameObject.layer == landingSpotsLayer)
            {
                Debug.Log("Landing!!");
                landing();
                return;
            }
        }
        
        targetDir = targetDir.normalized;
        currentSeq = DOTween.Sequence();
        float avoidTendency = 0.65f;
        Vector3 nextDir = Vector3.Slerp(selfObj.forward,  (1- avoidTendency) * targetDir + avoidTendency * avoidDir, turningFactor).normalized;
        float forwardDampingFactor = Mathf.Max(Vector3.Dot(nextDir, selfObj.forward), 0);
        Vector3 nextPos = selfObj.position + nextDir * forwardDampingFactor * step;
        currentSeq.Append(selfObj.DOMove(nextPos, movingDuration))
                  .Join(selfObj.DOLookAt(nextPos, turningDuration))
                  .AppendCallback(flyToTarget);
    }

    float landingDuration = 0.2f;

    public void landing() {
        Sequence mySequence = DOTween.Sequence();
        Vector3 nextDir = selfObj.forward - Vector3.Dot(selfObj.forward, target.up) * target.up; 
        mySequence.Append(selfObj.DOMove(target.position + target.up * 0f, landingDuration))
                 .Join(selfObj.DOLookAt(selfObj.position + nextDir, landingDuration))
                 .AppendCallback(landed);
        Invoke("playLandingAnimation", 0.7f);
    }

    public void playLandingAnimation()
    {
        bfAnimController.land();
    }

    public void landed()
    {
        Invoke("chooseTargetAndTakeOff", Random.Range(7f, 30f));
    }

    void OnCollisionEnter(Collision collision)
    {
        //Debug.Log("Collision!" + collision.gameObject.name);
        if (!bfAnimController.isFlying())
        {
            if (collision.gameObject.layer == handLayerIndex)
            {
                chooseTargetAndTakeOff();
            }
        }
        else
        {
            if (currentSeq != null && currentSeq.IsPlaying())
            {
                avoidDir = (selfObj.position - collision.contacts[0].point).normalized;
                currentSeq.Kill();
                currentSeq = null;
                flyToTarget();
            }
        }


    }

    void OnCollisionExit(Collision collision)
    {
        avoidDir = Vector3.zero;
    }


    void chooseTargetAndTakeOff()
    {
        if (!bfAnimController.isFlying() && !isTakingOff)
        {
            isTakingOff = true;
            target = wayPtsManager.getNextWayPt();
            while(Vector3.Distance(target.position,selfObj.position) < landingDist)
            {
                target = wayPtsManager.getNextWayPt();
            }
            takeOff();
        }
    }

}
