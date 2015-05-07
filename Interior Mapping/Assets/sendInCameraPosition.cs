using UnityEngine;
using System.Collections;

public class sendInCameraPosition : MonoBehaviour {
	Material _mat;
	private float val = 0;
	// Use this for initialization
	void Start () {
		_mat = gameObject.GetComponent<Renderer>().material;
		StartCoroutine (StartWave());
	}
	
	// Update is called once per frame
	void Update () {
		_mat.SetVector("_cameraPosition",Camera.main.transform.position);
	}
	private IEnumerator StartWave(){
		if (val == 0)
			val = 1;
		else
			val = 0;
		_mat.SetFloat ("_wave",val);
		yield return new WaitForSeconds (0.5f);
		StartCoroutine (StartWave());

	}
}
