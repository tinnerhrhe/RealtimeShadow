var cameraPosition = [30, 30, 30]

//生成的纹理的分辨率，纹理必须是标准的尺寸 256*256 1024*1024  2048*2048
var resolution = 2048;
var fbo;

GAMES202Main();

function GAMES202Main() {
	// Init canvas and gl
	const canvas = document.querySelector('#glcanvas');
	canvas.width = window.screen.width;
	canvas.height = window.screen.height;
	const gl = canvas.getContext('webgl');
	if (!gl) {
		alert('Unable to initialize WebGL. Your browser or machine may not support it.');
		return;
	}

	// Add camera
	const camera = new THREE.PerspectiveCamera(75, gl.canvas.clientWidth / gl.canvas.clientHeight, 1e-2, 1000);
	camera.position.set(cameraPosition[0], cameraPosition[1], cameraPosition[2]);

	// Add resize listener
	function setSize(width, height) {
		camera.aspect = width / height;
		camera.updateProjectionMatrix();
	}
	setSize(canvas.clientWidth, canvas.clientHeight);
	window.addEventListener('resize', () => setSize(canvas.clientWidth, canvas.clientHeight));

	// Add camera control
	const cameraControls = new THREE.OrbitControls(camera, canvas);
	cameraControls.enableZoom = true;
	cameraControls.enableRotate = true;
	cameraControls.enablePan = true;
	cameraControls.rotateSpeed = 0.3;
	cameraControls.zoomSpeed = 1.0;
	cameraControls.panSpeed = 0.8;
	cameraControls.target.set(0, 0, 0);

	// Add renderer
	const renderer = new WebGLRenderer(gl, camera);

	// Add lights
	// light - is open shadow map == true
	let lightPos = [0, 80, 80];
	let focalPoint = [0, 0, 0];
	let lightUp = [0, 1, 0]
	const directionLight = new DirectionalLight(5000, [1, 1, 1], lightPos, focalPoint, lightUp, true, renderer.gl);
	// light 2
	let lightPos_2 = [20, 60, 80];
	const directionLight_2 = new DirectionalLight(3000, [1, 1, 1], lightPos_2, focalPoint, lightUp, true, renderer.gl);
	renderer.addLight(directionLight);
	renderer.addLight(directionLight_2);

	// Add shapes
	
	let floorTransform = setTransform(0, 0, -30, 4, 4, 4);
	let obj1Transform = setTransform(0, 0, 0, 20, 20, 20);
	let obj2Transform = setTransform(40, 0, -40, 10, 10, 10);

	loadOBJ(renderer, 'assets/mary/', 'Marry', 'PhongMaterial', obj1Transform, 'marry1');
	loadOBJ(renderer, 'assets/mary/', 'Marry', 'PhongMaterial', obj2Transform, 'marry2');
	loadOBJ(renderer, 'assets/floor/', 'floor', 'PhongMaterial', floorTransform, 'floor');
	

	// let floorTransform = setTransform(0, 0, 0, 100, 100, 100);
	// let cubeTransform = setTransform(0, 50, 0, 10, 50, 10);
	// let sphereTransform = setTransform(30, 10, 0, 10, 10, 10);

	//loadOBJ(renderer, 'assets/basic/', 'cube', 'PhongMaterial', cubeTransform);
	// loadOBJ(renderer, 'assets/basic/', 'sphere', 'PhongMaterial', sphereTransform);
	//loadOBJ(renderer, 'assets/basic/', 'plane', 'PhongMaterial', floorTransform);


	function createGUI() {
		const gui = new dat.gui.GUI();
		// const panelModel = gui.addFolder('Model properties');
		// panelModelTrans.add(GUIParams, 'x').name('X');
		// panelModel.open();
	}
	createGUI();

	var xshift = 0;
	var zshift = 0;
	var posstate = 0;
	var scale = 1.0
	var scalestate = true;

	function mainLoop(now) {
		cameraControls.update();

		renderer.render();
		requestAnimationFrame(mainLoop);

		renderer.setTranslateScale('marry1', [xshift, 0, zshift], [20*scale, 20*scale, 20*scale]);
		renderer.setTranslateScale('marry2', [40 + xshift, 0, -40 + zshift], [10*scale, 10*scale, 10*scale]);

		switch(posstate) {
			case 0:
				xshift += 0.1; 
				if (xshift >= 30) posstate = 1;
				break;
			case 1:
				zshift += 0.1;
				if (zshift >= 30) posstate = 2;
				break;
			case 2:
				xshift -= 0.1;
				if (xshift <= -30) posstate = 3;
				break;
			case 3:
				zshift -= 0.1;
				if (zshift <= -30) posstate = 0;
				break;
		}

		scale += scalestate ? 0.002 : -0.002;

		if (scale >= 1.5) scalestate = false;
		if (scale <= 0.5) scalestate = true;

	}
	requestAnimationFrame(mainLoop);
}

function setTransform(t_x, t_y, t_z, s_x, s_y, s_z) {
	return {
		modelTransX: t_x,
		modelTransY: t_y,
		modelTransZ: t_z,
		modelScaleX: s_x,
		modelScaleY: s_y,
		modelScaleZ: s_z,
	};
}
