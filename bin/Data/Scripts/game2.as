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
	fakeboxNode.scale = Vector3(6000.0f, 6000.0f, 6000.0f);
	StaticModel@ fakeboxObject = fakeboxNode.CreateComponent("StaticModel");
	fakeboxObject.model = cache.GetResource("Model", "Models/Box.mdl");
	

	Node@ lightNode = scene_.CreateChild("DirectionalLight");
	lightNode.direction = Vector3(0.6f, -1.0f, 0.8f); // The direction vector does not need to be normalized
	Light@ light = lightNode.CreateComponent("Light");
	light.lightType = LIGHT_DIRECTIONAL;
	light.color = Color(0.2f,0.1f,0.4f,1.0);

	Node@ cameraNode = scene_.CreateChild("CamNode");
	cameraNode.position = Vector3(0.0f , 14.0f , -20.0f);
    Camera@ camera = cameraNode.CreateComponent("Camera");
	Viewport@ mainVP = Viewport(scene_, camera);
    freelookCam@ flcam = cast<freelookCam>(cameraNode.CreateScriptObject(scriptFile, "freelookCam"));
    flcam.Init();
	camera.farClip = 800;
	
	Node@ fooball = cameraNode.CreateChild("fooball");
	fooball.position = Vector3(0.0f,0.0f,31.0f);
	StaticModel@ ballModel = fooball.CreateComponent("StaticModel");
	ballModel.model = cache.GetResource("Model", "Models/Sphere.mdl");
	Light@ fplight = fooball.CreateComponent("Light");
	fplight.color = Color(1.3,0.8,0.6,1.0);
	fplight.range = 15;

	renderer.viewports[0] = mainVP;
	renderpath = mainVP.renderPath.Clone();

	//renderer.hdrRendering = true;


	renderpath.Load(cache.GetResource("XMLFile","RenderPaths/DeferredHWDepth.xml"));
	renderer.viewports[0].renderPath = renderpath;


	//renderer.specularLighting = false;

	//renderer.shadowMapSize = 2048;
	//renderer.shadowQuality = 3;

	camera.farClip = 12000;
	camera.nearClip = 0.6;

	camera.fov = 50.0f;

	SubscribeToEvent("Update", "HandleUpdate");
	SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");

	   for (int i=0; i<100; i++)
	{
	   Node@ plightNode = scene_.CreateChild("pointlight");
	   plightNode.position = Vector3(500-Random(1000), Random(50),500 - Random(1000));
		Light@ plight = plightNode.CreateComponent("Light");
		//light.lightType = LIGHT_DIRECTIONAL;
		plight.color = Color(0.2+Random(1.0f),0.2+Random(1.0f),0.2+Random(1.0f),1.0);
		plight.range = 20 + Random(120);
	}
	
	Geometry@ rayScreenGeom = RayScreen();
	Model@ rayScreenModel = Model();
    
   rayScreenModel.numGeometries = 1;
   rayScreenModel.SetGeometry(0, 0, rayScreenGeom);
   Material@ rayScreenMat = Material();
   rayScreenMat = cache.GetResource("Material","Materials/RayScreen.xml");
   
   Node@ rayScreenNode = cameraNode.CreateChild("rayScreen");
   rayScreenNode.position = Vector3(0.0,0.0, 100.0);
   rayScreenModel.boundingBox = BoundingBox(Vector3(-1000.0f,-1000.0f,-1000.0f), Vector3(1000.0f,1000.0f,1000.0f));
   StaticModel@ rsobject = rayScreenNode.CreateComponent("StaticModel");
   rsobject.model = rayScreenModel;
   
   rsobject.material = rayScreenMat;
   rsobject.castShadows = false;

}

Geometry@ RayScreen()
{
	IntVector2 res = graphics.resolutions[0];
	int numVerts = res.x * res.y;
	Vector2 resnorm = Vector2(2.0/float(res.x),2.0/float(res.y));
	
	VertexBuffer@ vb = VertexBuffer();
	IndexBuffer@ ib = IndexBuffer();
    Geometry@ geom = Geometry();
    
    vb.shadowed = true;
    vb.SetSize(numVerts, MASK_POSITION);
    VectorBuffer temp;
	
	for (int u=0; u<res.y;u++)
	{
		for (int i=0; i<res.x;i++)
		{
			temp.WriteFloat( resnorm.x * float(i) );
			temp.WriteFloat( resnorm.y * float(u) );
			temp.WriteFloat( 1.0 );
		}
	}
	
	vb.SetData(temp);
	
	ib.shadowed = true;
    ib.SetSize(numVerts, false);
    temp.Clear();
    
    for (int i = 0; i<numVerts; ++i)
    {
        temp.WriteUShort(i);

    }
    
   ib.SetData(temp);

	
	geom.SetVertexBuffer(0, vb);
	geom.SetIndexBuffer(ib);
	geom.SetDrawRange(POINT_LIST, 0, numVerts);
	 
	return geom;
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
