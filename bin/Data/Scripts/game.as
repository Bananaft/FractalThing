#include "freelookCam.as";
Scene@ scene_;
bool wireframe =false;
RenderPath@ renderpath;

void Start()
{
	cache.autoReloadResources = true;

    scene_ = Scene();
	CreateConsoleAndDebugHud();

	SubscribeToEvent("KeyDown", "HandleKeyDown");

  //SCENE
  scene_.CreateComponent("Octree");

	Node@ planeNode = scene_.CreateChild("Plane");
	planeNode.scale = Vector3(100.0f, 1.0f, 100.0f);
	planeNode.position = Vector3(0.0f,12.0f,0.0f);
	StaticModel@ planeObject = planeNode.CreateComponent("StaticModel");
	planeObject.model = cache.GetResource("Model", "Models/Plane.mdl");
	
	Node@ fakeboxNode = scene_.CreateChild("Plane");
	fakeboxNode.scale = Vector3(20000.0f, 20000.0f, 20000.0f);
	StaticModel@ fakeboxObject = fakeboxNode.CreateComponent("StaticModel");
	fakeboxObject.model = cache.GetResource("Model", "Models/Box.mdl");
	

	//Node@ lightNode = scene_.CreateChild("DirectionalLight");
	//lightNode.direction = Vector3(0.6f, -1.0f, 0.8f); // The direction vector does not need to be normalized
	//Light@ light = lightNode.CreateComponent("Light");
	//light.lightType = LIGHT_DIRECTIONAL;
	//light.color = Color(0.2f,0.1f,0.4f,1.0) * 0.01;

	Node@ cameraNode = scene_.CreateChild("CamNode");
	cameraNode.position = Vector3(0.0f , 14.0f , -20.0f);
    Camera@ camera = cameraNode.CreateComponent("Camera");
	Viewport@ mainVP = Viewport(scene_, camera);
    freelookCam@ flcam = cast<freelookCam>(cameraNode.CreateScriptObject(scriptFile, "freelookCam"));
    flcam.Init();
	camera.farClip = 1200;
	
	Node@ fooball = cameraNode.CreateChild("fooball");
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
	splight.fov = 10.;
	splight.range = 250;
	
/*	Node@ fooPlaneNode = cameraNode.CreateChild("Plane");
	fooPlaneNode.scale = Vector3(150.0f, 1.0f, 150.0f);
	fooPlaneNode.rotation = Quaternion(-90.,0.,0.);
	fooPlaneNode.position = Vector3(0.0f,-2.0f,100.0f);
	StaticModel@ fooPlaneObject = fooPlaneNode.CreateComponent("StaticModel");
	fooPlaneObject.model = cache.GetResource("Model", "Models/Plane.mdl");*/

	renderer.viewports[0] = mainVP;
	renderpath = mainVP.renderPath.Clone();

	renderer.hdrRendering = true;


	renderpath.Load(cache.GetResource("XMLFile","RenderPaths/Deferred.xml"));
	renderpath.Append(cache.GetResource("XMLFile","PostProcess/AutoExposure.xml"));
	renderpath.Append(cache.GetResource("XMLFile","PostProcess/BloomHDR.xml"));
	renderer.viewports[0].renderPath = renderpath;


	//renderer.specularLighting = false;

	//renderer.shadowMapSize = 2048;
	//renderer.shadowQuality = 3;

	camera.farClip = 12000;
	camera.nearClip = 0.6;

	camera.fov = 50.0f;

	SubscribeToEvent("Update", "HandleUpdate");
	SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");

	   for (int i=0; i<800; i++)
	{
	   Node@ plightNode = scene_.CreateChild("pointlight");
	   plightNode.position = Vector3(500-Random(1000),1500-Random(3000),500-Random(1000));
		Light@ plight = plightNode.CreateComponent("Light");
		//light.lightType = LIGHT_DIRECTIONAL;
		plight.color = Color(0.2+Random(1.0f),0.2+Random(1.0f),0.2+Random(1.0f),1.0) * (0.6 + Random(16.0f));
		plight.range = 15 + Random(100);
		
		if (Random(1.0)>0.8) plight.lightType = LIGHT_SPOT;
	}


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

        }


}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{

}
