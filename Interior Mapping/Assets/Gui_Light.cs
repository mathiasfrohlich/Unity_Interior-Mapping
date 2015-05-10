using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class Gui_Light : MonoBehaviour {

	public Image BackGround;
	public Image Knob;
	public Slider slider;
	public Text value;

	Material _mat;

	// Use this for initialization
	void Start () {
		_mat = gameObject.GetComponent<Renderer>().material;

	}
	
	// Update is called once per frame
	void Update () {
		float val = slider.value;

		Knob.color = new Color(slider.value,slider.value,slider.value);

//		Color c = new Color(val,val,val);
//		slider.colors.pressedColor = c;

		//BackGround.color = new Color(slider.value,slider.value,slider.value);

		value.text = slider.value.ToString();

		_mat.SetFloat("_light",slider.value);

	}
}
