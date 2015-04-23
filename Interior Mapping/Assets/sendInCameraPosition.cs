using UnityEngine;
using System.Collections;

public class sendInCameraPosition : MonoBehaviour {
	Material _mat;
	// Use this for initialization
	void Start () {
		_mat = gameObject.GetComponent<Renderer>().material;
	}
	
	// Update is called once per frame
	void Update () {
		_mat.SetVector("_cameraPosition",Camera.main.transform.position);
	}
}
