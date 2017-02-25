#include "freelookCam.as";
Scene@ scene_;
bool wireframe =false;
bool fpscap =false;
bool fctype =false;
RenderPath@ renderpath;

Node@ veh;
Node@ cameraNode;
Node@ fakeboxNode;
UIElement@ LegendNode;

void Start()
{
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
					"Ctrl - super speed \n"
					"Alt - ludicrous speed \n"
					"Space - move vessel to camera position\n"
					"E - spawn some random big lights around\n"
					"LMB - shoot tiny flying lights \n"
					"RMB - spawn big blue light\n"
					"T -  spawn teapot \n\n"
					
					"Z - switch fractal type\n"
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

	}  else if (key == KEY_SPACE)
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
	} else if (key == KEY_Z)
	{
		if (fctype)
		{
			fctype = false;
			setFractalType();
		} else {
			fctype = true;
			setFractalType();
		}

	} else if (key == KEY_E)
	{
		spawnlights(cameraNode.position, 6);
	} else if (key == KEY_X)
	{
		Vector3 cpos = cameraNode.position;

		scene_.RemoveAllChildren();
		SetupScene();
		setFractalType();
		cameraNode.position = cpos;

	} else if (key == KEY_F1)
	{
		if (LegendNode.visible) 
		{
			LegendNode.visible = false;
		} else {
			LegendNode.visible = true;
		}
	}


}

void setFractalType()
{
		renderpath = renderer.viewports[0].renderPath.Clone();
		RenderPathCommand rpc;
		
		if (fctype)
		{

			for (int i=3; i<7; i++)
			{
				rpc = renderpath.commands[i];
				rpc.pixelShaderDefines = "PREMARCH FCTYP";
				renderpath.commands[i] = rpc;
			}
			rpc = renderpath.commands[7];
			rpc.pixelShaderDefines = "DEFERRED FCTYP";
			renderpath.commands[7] = rpc;
			renderer.viewports[0].renderPath = renderpath;
		
		} else {
			
			for (int i=3; i<7; i++)
			{
				rpc = renderpath.commands[i];
				rpc.pixelShaderDefines = "PREMARCH";
				renderpath.commands[i] = rpc;
			}
			rpc = renderpath.commands[7];
			rpc.pixelShaderDefines = "DEFERRED";
			renderpath.commands[7] = rpc;
			renderer.viewports[0].renderPath = renderpath;
		
		}
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
