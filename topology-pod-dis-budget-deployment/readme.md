Deployment Strategy to follow
==============================
For every deployment we need to ensure configure the topology spread constraint and pod disruption budget.
This will helps to run the application even when there is voluntarily made mistakes.

Note:
Min available suppose to be at least 60%, eks should have 3 nodes with 5 replicas always is best practices

Follow the below strategy and calculation should be percentage only (60%) while definig the Min Available in Deployment

If you have Nodes: 2

Min Available Formulae = Total no of pods - Max Pods on one node/Total Pods

PODS | Distribution (based on no of nodes) | Max Pods on One Node| Min Available

2    |   1:1                               |        1             | (2-1)/2*100=50%


If you have Nodes: 3

PODS | Distribution (based on no of nodes) | Max Pods on One Node| Min Available

3    |   1:1:1                             |        1             | (3-1)/3*100=66%
4    |  2:1:1                              |        2             | (4-2)/4*100=50%
5    |  2:2:1                              |        2             | (5-2)/5*100=60% 
                                                                    (This is why to run the cluster with 3 nodes & 5 replicas)

Detail Steps wise to follow:

Part 1: How the Order Works ExactlyThink of this as two completely separate stages. 

    Stage 1 is the Scheduler deciding where to place a new pod. 

    Stage 2 is the Eviction API handling maintenance.

Stage 1: 
The Scheduling Filter (For creating pods)When you run kubectl apply, the Kubernetes Scheduler runs your 5 replicas through a pipeline of elimination, one pod at a time:[ All Nodes in Cluster ]
         │
         ▼
 1. Node Affinity ───────► Kicks out nodes that don't match your hardware/labels.
         │
         ▼
 2. Pod Anti-Affinity ───► Kicks out nodes holding pods you want to avoid.
         │
         ▼
 3. Topology Spread ─────► Scores remaining nodes to see which one keeps the cluster balanced.
         │
         ▼
[ Final Node Selected ]

    Step 1: Node Affinity (The Hardware Filter): The scheduler looks at your cluster. 
    If your Node Affinity says "Only use nodes with SSDs," it instantly throws away all non-SSD nodes.

    Step 2: Pod Affinity / Anti-Affinity (The Neighbor Filter): Next, it looks at the remaining nodes. If your Pod Anti-Affinity says "Don't put me near the database pod," it throws away any node currently running a database pod.

    Step 3: Topology Spread Constraint (The Balancer): Now, the scheduler is left with a small pool of valid nodes. 
    It counts how many of your pods are already on those nodes/zones, calculates the skew, and picks the node that keeps things most perfectly balanced.

Stage 2: 
The Eviction Guard (For upgrading/draining nodes)Pod Disruption Budget (PDB) does not participate in the scheduling pipeline above.Instead, it sits quietly on the side. 
When an administrator or automation tries to upgrade or drain a node (kubectl drain), the Eviction API checks your PDB.If draining that node would drop your running pods below your minAvailable limit, Kubernetes blocks the drain command and protects your app.

Part 2: Industry Standards for 3 Nodes and 5 ReplicasWhen your Replicas (5) outnumber your Nodes (3), you have a mathematical certainty: Pods must share nodes. (5 pods divided by 3 nodes means some nodes must hold 2 pods).Because pods must share nodes, using strict "Hard" rules will cause your deployment to break or freeze. 

Here is the industry-standard approach to configuring this architecture:

* Rule 1: Use ScheduleAnyway for Hostname TopologyNever use whenUnsatisfiable: DoNotSchedule for kubernetes.io/hostname when replicas exceed nodes. If you do, Kubernetes will refuse to schedule pods 4 and 5, leaving them stuck in a Pending state forever. Use ScheduleAnyway so it balances them as best as it can (e.g., Node1: 2 pods, Node2: 2 pods, Node3: 1 pod).

* Rule 2: Prefer Topology Spread over Pod Anti-AffinityIn modern Kubernetes, Topology Spread Constraints have replaced Pod Anti-Affinity for standard high-availability. Pod Anti-Affinity is "all-or-nothing" and heavy on cluster performance. Topology Spread is smarter because it allows math-based, soft balancing.

* Rule 3: Set PDB carefully to allow upgradesWith 5 replicas, a standard production choice is maxUnavailable: 1 or minAvailable: 4. This ensures that if a node is drained, only 1 or 2 pods are lost at a time, keeping your application online and healthy.