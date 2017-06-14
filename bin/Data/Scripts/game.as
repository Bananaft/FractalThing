#include "freelookCam.as";
Scene@ scene_;
bool wireframe =false;
bool fpscap =false;
bool fog = true;
String  fractaltyp = " ";
//uint fctype = 0;
RenderPath@ renderpath;

Node@ veh;
Node@ cameraNode;
Node@ fakeboxNode;
UIElement@ LegendNode;


void Start()
{
	graphics.windowTitle = "Yedoma Globula fractal techdemo";
	//graphics.SetMode(1280,720);
	//		SetMode (int width, int height, bool fullscreen, bool borderless, bool resizable, bool highDPI, bool vsync, bool tripleBuffer, int multiSample)
	//graphics.SetMode(1280,    720,        false,           false,             true,               false,       false,      false,            0);
	
	cache.autoReloadResources = true;

    scene_ = Scene();
	CreateConsoleAndDebugHud();

	SubscribeToEvent("KeyDown", "HandleKeyDown");

  //SCENE
	scene_.CreateComponent("Octree");
	
	renderer.hdrRendering = true;
	
	
	SetupScene();
	spawnlights(cameraNode.position, 26);
	
	SubscribeToEvent("Update", "HandleUpdate");
	SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
	
		
	LegendNode = ui.root.CreateChild("UIElement");
	LegendNode.SetPosition(200 , 10);
	LegendNode.horizontalAlignment = HA_LEFT;
	LegendNode.verticalAlignment = VA_TOP;
	
	Text@ helpText = LegendNode.CreateChild("Text");
	helpText.SetFont(cache.GetResource("Font", "Fonts/Anonymous Pro.ttf"), 10);
	helpText.horizontalAlignment = HA_LEFT;
	helpText.verticalAlignment = VA_TOP;
	helpText.SetPosition(0,0);
	helpText.color = Color(1,1,0.5);;
	helpText.text =
					"F1 - toggle help \n"
					"F2 - show profiler \n"
					"F12 - take screenshot \n\n"
					
					"WASD and Mouse - move camera around\n"
					"Mouse wheel - Zoom\n"
					"Shift - move faster \n"
					"Ctrl - move slower \n"
					"Alt - super speed \n\n"
					
					"E - spawn some random big lights around\n"
					"LMB - shoot flying lights \n"
					"RMB - spawn single blue light\n"
					"T -  spawn teapot \n"
					"Space - move vessel to camera position\n"
					"N - toggle sky\n\n"
					
					"1-4 - switch fractal type\n"
					"R - return camera to starting location\n"
					"X - clear scene\n"
					"V - toggle wireframe\n"
					"C - cap FPS to 30\n";


}

void SetupScene()
{
	
	
	Node@ zoneNode = scene_.CreateChild("Zone");
    Zone@ zone = zoneNode.CreateComponent("Zone");
    zone.boundingBox = BoundingBox(-20000.0f, 20000.0f);
    zone.ambientColor = Color(0.0f, 0.0f, 0.0f);
    //zone.fogColor = Color(0.5f, 0.5f, 0.7f);
    //zone.fogStart = 100.0f;
    //zone.fogEnd = 300.0f;

	fakeboxNode = scene_.CreateChild("Plane");
	fakeboxNode.scale = Vector3(20000.0f, 20000.0f, 20000.0f);
	StaticModel@ fakeboxObject = fakeboxNode.CreateComponent("StaticModel");
	fakeboxObject.model = cache.GetResource("Model", "Models/Box.mdl");


	cameraNode = scene_.CreateChild("CamNode");
	cameraNode.position = Vector3(0.0f , 14.0f , -20.0f);
    Camera@ camera = cameraNode.CreateComponent("Camera");
	Viewport@ mainVP = Viewport(scene_, camera);
	renderer.viewports[0] = mainVP;
	
	//*
	Node@ testplane = cameraNode.CreateChild("testNode");
	StaticModel@ testPlaneModel = testplane.CreateComponent("StaticModel");
	testPlaneModel.model = cache.GetResource("Model", "Models/Plane.mdl");
	Material@ testpanelMat = cache.GetResource("Material", "Materials/testPlane.xml");
	testPlaneModel.material = testpanelMat;
	testplane.position = Vector3(0.,-2.,100);
	testplane.Rotate(Quaternion(-90.,0.,0.));
	testplane.scale = Vector3(100.,100.,100.);
	//*/
	
	
	renderpath = mainVP.renderPath.Clone();

	renderpath.Load(cache.GetResource("XMLFile","RenderPaths/Deferred.xml"));
	renderpath.Append(cache.GetResource("XMLFile","PostProcess/AutoExposure.xml"));
	renderpath.Append(cache.GetResource("XMLFile","PostProcess/BloomHDR.xml"));
	renderer.viewports[0].renderPath = renderpath;
	
    freelookCam@ flcam = cast<freelookCam>(cameraNode.CreateScriptObject(scriptFile, "freelookCam"));
    flcam.Init();
	
	camera.farClip = 12000;
	camera.nearClip = 0.2;

	camera.fov = 50.0f;
	
	veh = scene_.InstantiateXML(cache.GetResource("XMLFile", "Objects/barkas.xml"), Vector3(0,30,-50),Quaternion(0,0,0));

				
}

void CreateConsoleAndDebugHud()
{
    // Get default style
    XMLFile@ xmlFile = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    if (xmlFile is null)
        return;

    // Create console
    Console@ console = engine.CreateConsole();
    console.defaultStyle = xmlFile;
    console.background.opacity = 0.8f;

    // Create debug HUD
    DebugHud@ debugHud = engine.CreateDebugHud();
    debugHud.defaultStyle = xmlFile;

}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
    {

    }

void HandleKeyDown(StringHash eventType, VariantMap& eventData)
{	
	
    int key = eventData["Key"].GetInt();

    // Close console (if open) or exit when ESC is pressed
    if (key == KEY_ESCAPE)
    {
        if (!console.visible)
            engine.Exit();
        else
            console.visible = false;
    }

    // Toggle console with F1
    else if (key == 96)
        console.Toggle();

    // Toggle debug HUD with F2
    else if (key == KEY_F2)
        debugHud.ToggleAll();

    // Take screenshot
    else if (key == KEY_F12)
	{
		Image@ screenshot = Image();
		graphics.TakeScreenShot(screenshot);
		// Here we save in the Data folder with date and time appended
		screenshot.SavePNG(fileSystem.programDir + "Data/Screenshot_" +
			time.timeStamp.Replaced(':', '_').Replaced('.', '_').Replaced(' ', '_') + ".png");
	} else if (key == KEY_V)
	{

		Camera@ cam = renderer.viewports[0].camera;
		if (wireframe){
			cam.fillMode = FILL_SOLID;
			wireframe = false;
		} else {
			cam.fillMode = FILL_WIREFRAME;
			wireframe = true;
		}

	} else if (key == KEY_C)
	{

		if (fpscap){
			engine.maxFps = 00;
			fpscap = false;
		} else {
			engine.maxFps = 30;
			fpscap = true;
		}

	} else if (key == KEY_N)
	{

		if (fog){
			fog = false;
			setRndCommandParam(fractaltyp);
		} else {
			
			fog = true;
			setRndCommandParam(fractaltyp);
		}

	} else if (key == KEY_SPACE)
	{
		veh.position = cameraNode.position;
		veh.rotation = cameraNode.rotation;
	} else if (key == KEY_T)
	{
		Node@ tpnode = scene_.CreateChild("Plane");
		tpnode.scale = Vector3(8.0f, 8.0f, 8.0f);
		tpnode.position = cameraNode.position + cameraNode.rotation * Vector3(0,0,15.);;
		tpnode.rotation = cameraNode.rotation;
		StaticModel@ tpObject = tpnode.CreateComponent("StaticModel");
		tpObject.model = cache.GetResource("Model", "Models/Teapot.mdl");
	} else if (key == KEY_E)
	{
		spawnlights(cameraNode.position, 6);
	} else if (key == KEY_X)
	{
		Vector3 cpos = cameraNode.position;

		scene_.RemoveAllChildren();
		SetupScene();
		//setFractalType();
		cameraNode.position = cpos;

	} else if (key == KEY_F1)
	{
		if (LegendNode.visible) 
		{
			LegendNode.visible = false;
		} else {
			LegendNode.visible = true;
		}
	} else if (key == KEY_1)
	{
		fractaltyp = "FCTYP_1";
		setRndCommandParam(fractaltyp);
	} else if (key == KEY_2)
	{
		fractaltyp = "FCTYP_2";
		setRndCommandParam(fractaltyp);
	} else if (key == KEY_3)
	{
		fractaltyp = "FCTYP_3";
		setRndCommandParam(fractaltyp);
	} else if (key == KEY_4)
	{
		fractaltyp = "FCTYP_4";
		setRndCommandParam(fractaltyp);
	} else if (key == KEY_5)
	{
		fractaltyp = "FCTYP_5";
		setRndCommandParam(fractaltyp);
	} else if (key == KEY_6)
	{
		fractaltyp = "FCTYP_6";
		setRndCommandParam(fractaltyp);
	} else if (key == KEY_7)
	{
		fractaltyp = "FCTYP_7";
		setRndCommandParam(fractaltyp);
	} else if (key == KEY_8)
	{
		fractaltyp = "FCTYP_8";
		setRndCommandParam(fractaltyp);
	} else if (key == KEY_9)
	{
		fractaltyp = "FCTYP_9";
		setRndCommandParam(fractaltyp);
	}


}

void setRndCommandParam(String param)
{
	renderpath = renderer.viewports[0].renderPath.Clone();
	RenderPathCommand rpc;
	
	
	
	for (int i=3; i<7; i++)
	{
		rpc = renderpath.commands[i];
		rpc.pixelShaderDefines = "PREMARCH " + param;
		renderpath.commands[i] = rpc;
	}
	rpc = renderpath.commands[7];
	rpc.pixelShaderDefines = "DEFERRED " + param;
	renderpath.commands[7] = rpc;
	
	if (fog) param += " FOG";
	rpc = renderpath.commands[8];
	rpc.pixelShaderDefines = "DEFERRED "  + param;
	renderpath.commands[8] = rpc;
	
	renderer.viewports[0].renderPath = renderpath;
		
}

void setFractalType(int fctNum)
{
		

}

void spawnlights (Vector3 pos, int numLights)
{
	
	float sc = 400;

	for (int i=0; i<numLights; i++)
	{
	   Node@ plightNode = scene_.CreateChild("pointlight");
	   plightNode.position = pos + Vector3(sc/2-Random(sc),sc/2-Random(sc),sc/2-Random(sc));
		Light@ plight = plightNode.CreateComponent("Light");
		//light.lightType = LIGHT_DIRECTIONAL;
		plight.color = Color(0.2+Random(1.0f),0.2+Random(1.0f),0.2+Random(1.0f),1.0);
		plight.range = 80 + Random(60);
		//plight.fov = 5+Random(120);
		plightNode.Rotate(Quaternion(Random(360),Random(360),0.f));
		//if (Random(1.0)>0.0) plight.lightType = LIGHT_SPOT;
	}
	
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
	fakeboxNode.position = cameraNode.position;
	veh.position += veh.rotation * Vector3(0.,0.,0.1);
	veh.Rotate(Quaternion(0.,0.2,0.));
}
