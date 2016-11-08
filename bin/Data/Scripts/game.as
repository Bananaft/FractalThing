#include "freelookCam.as";
Scene@ scene_;
bool wireframe =false;
RenderPath@ renderpath;

Node@ veh;
Node@ cameraNode;

void Start()
{
	cache.autoReloadResources = true;

    scene_ = Scene();
	CreateConsoleAndDebugHud();

	SubscribeToEvent("KeyDown", "HandleKeyDown");

  //SCENE
  scene_.CreateComponent("Octree");

    Node@ zoneNode = scene_.CreateChild("Zone");
    Zone@ zone = zoneNode.CreateComponent("Zone");
    zone.boundingBox = BoundingBox(-20000.0f, 20000.0f);
    zone.ambientColor = Color(0.0f, 0.0f, 0.0f);
    //zone.fogColor = Color(0.5f, 0.5f, 0.7f);
    //zone.fogStart = 100.0f;
    //zone.fogEnd = 300.0f;

	Node@ fakeboxNode = scene_.CreateChild("Plane");
	fakeboxNode.scale = Vector3(20000.0f, 20000.0f, 20000.0f);
	StaticModel@ fakeboxObject = fakeboxNode.CreateComponent("StaticModel");
	fakeboxObject.model = cache.GetResource("Model", "Models/Box.mdl");


	cameraNode = scene_.CreateChild("CamNode");
	cameraNode.position = Vector3(0.0f , 14.0f , -20.0f);
    Camera@ camera = cameraNode.CreateComponent("Camera");
	Viewport@ mainVP = Viewport(scene_, camera);
    freelookCam@ flcam = cast<freelookCam>(cameraNode.CreateScriptObject(scriptFile, "freelookCam"));
    flcam.Init();
	camera.farClip = 1200;

/*	Node@ fooball = cameraNode.CreateChild("fooball");
	fooball.position = Vector3(0.0f,-4.0f,10.0f);
	StaticModel@ ballModel = fooball.CreateComponent("StaticModel");
	ballModel.model = cache.GetResource("Model", "Models/Sphere.mdl");
	//Light@ fplight = fooball.CreateComponent("Light");
	//fplight.color = Color(1.3,0.8,0.6,1.0);
	//fplight.range = 25;

	Node@ spotNode = fooball.CreateChild("spotNode");
	Light@ splight = fooball.CreateComponent("Light");
	splight.color = Color(1.9,2.8,3.6,1.0);
	splight.lightType = LIGHT_SPOT;
	splight.fov = 30.;
	splight.range = 250;*/



	renderer.viewports[0] = mainVP;
	renderpath = mainVP.renderPath.Clone();

	renderer.hdrRendering = true;
	//engine.maxFps = 30;

	renderpath.Load(cache.GetResource("XMLFile","RenderPaths/Deferred.xml"));
	renderpath.Append(cache.GetResource("XMLFile","PostProcess/AutoExposure.xml"));
	renderpath.Append(cache.GetResource("XMLFile","PostProcess/BloomHDR.xml"));
	renderer.viewports[0].renderPath = renderpath;


	//renderer.specularLighting = false;


	camera.farClip = 12000;
	camera.nearClip = 0.2;

	camera.fov = 50.0f;

	SubscribeToEvent("Update", "HandleUpdate");
	SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");

	   for (int i=0; i<500; i++)
	{
	   Node@ plightNode = scene_.CreateChild("pointlight");
	   plightNode.position = Vector3(250-Random(500),250-Random(500),250-Random(500));
		Light@ plight = plightNode.CreateComponent("Light");
		//light.lightType = LIGHT_DIRECTIONAL;
		plight.color = Color(0.2+Random(1.0f),0.2+Random(1.0f),0.2+Random(1.0f),1.0) * (0.1 + Random(1.0f));
		plight.range = 50 + Random(30);
		//plight.fov = 5+Random(120);
		plightNode.Rotate(Quaternion(Random(360),Random(360),0.f));
		//if (Random(1.0)>0.0) plight.lightType = LIGHT_SPOT;
	}

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
    else if (key == KEY_F1)
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

	} else if (key == KEY_SPACE)
	{
		veh.position = cameraNode.position;
		veh.rotation = cameraNode.rotation;
	}


}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
	//veh.position += veh.rotation * Vector3(0.,0.,0.1);
}
