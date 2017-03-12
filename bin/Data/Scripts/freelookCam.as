class freelookCam : ScriptObject
{
float yaw = 0.0f; // Camera yaw angle
float pitch = 0.0f; // Camera pitch angle
float roll = 0.0f;
Vector3 vel;
float boost = 8.;
float base_speed = 45. * 2.;
float MOVE_SPEED;

void Init()
    {

        //node.position = Vector3(0,0,0);
    }

void Update(float timeStep)
	{
        // Do not move if the UI has a focused element (the console)
        if (ui.focusElement !is null)
            return;
        Camera@ cam = node.GetComponent("camera");
        // Movement speed as world units per second
        			
		if (input.keyDown['w'] or input.keyDown['a'] or input.keyDown['d'] or input.keyDown['s'])
		{
			if (input.keyDown[KEY_SHIFT]) MOVE_SPEED = Lerp(MOVE_SPEED, base_speed * boost, Min(5 * timeStep,1.)); 
			else if (input.keyDown[KEY_ALT]) MOVE_SPEED = Lerp(MOVE_SPEED, base_speed * boost * boost * boost, Min(5 * timeStep,1.)); 
			else MOVE_SPEED = Lerp(MOVE_SPEED, base_speed, Min(5 * timeStep,1.)); 
		
		} else {
			MOVE_SPEED = base_speed;
		}
		
		if (input.keyDown[KEY_CTRL]) MOVE_SPEED = base_speed/16;
		
		
        // Mouse sensitivity as degrees per pixel
        const float MOUSE_SENSITIVITY = 0.1 * 1/cam.zoom;

        // Read WASD keys and move the camera scene node to the corresponding direction if they are pressed
        if (input.keyDown['W'])
            vel += node.rotation * Vector3(0.0f, 0.0f, 1.0f) * timeStep;
        if (input.keyDown['S'])
            vel += node.rotation * Vector3(0.0f, 0.0f, -1.0f) * timeStep;
        if (input.keyDown['A'])
            vel += node.rotation * Vector3(-1.0f, 0.0f, 0.0f) * timeStep;
        if (input.keyDown['D'])
			vel += node.rotation * Vector3(1.0f, 0.0f, 0.0f) * timeStep;
		
		//node.Translate(vel * MOVE_SPEED * timeStep);	
		node.position += vel * MOVE_SPEED * timeStep;
		
		vel *= Max(1. - 4. * timeStep, 0. );
        
		if (input.keyDown['Q'])
            roll += 45 * timeStep;
        else
            roll = 0.0;
			
		if (input.keyDown['R'])
           node.position = Vector3(0.0f , 14.0f , -20.0f);
		   
		if (input.mouseButtonPress[MOUSEB_LEFT])
		{
			Node@ lnode = scene_.CreateChild();
			lnode.position = node.position + node.rotation * Vector3(0,-2,-5.);
			Light@ plight = lnode.CreateComponent("Light");
			plight.color = Color(0.8+Random(0.4),0.6+Random(0.4),0.4+Random(0.4)) * 1.05;
			plight.range = 120;
			
			flyer@ lighfly = cast<flyer>(lnode.CreateScriptObject(scriptFile, "flyer"));
			lighfly.Init( node.rotation * Vector3(0,0,100));
		}
		
		if (input.mouseButtonPress[MOUSEB_RIGHT])
		{
			Node@ lnode = scene_.CreateChild();
			lnode.position = node.position + node.rotation * Vector3(0,0,5.);
			Light@ plight = lnode.CreateComponent("Light");
			plight.color = Color(0.2,0.8,1.2) * 0.2;
			plight.range = 90;
		}



            // Use this frame's mouse motion to adjust camera node yaw and pitch. Clamp the pitch between -90 and 90 degrees
        IntVector2 mouseMove = input.mouseMove;
        yaw += MOUSE_SENSITIVITY * mouseMove.x;
        pitch += MOUSE_SENSITIVITY * mouseMove.y;
        pitch = Clamp(pitch, -90.0f, 90.0f);

         // Construct new orientation for the camera scene node from yaw and pitch. Roll is fixed to zero
        node.rotation = Quaternion(pitch, yaw, roll);

        int mousescroll = input.mouseMoveWheel;
        cam.zoom = Clamp(cam.zoom + mousescroll * cam.zoom * 0.2, 0.8 , 20.0 );
		//log.Info(node.position.y);
        //check terrain collision
        //Vector3 campos = node.position;
        //Terrain@ terr = scene.GetChild("terrain").GetComponent("terrain");
        //float ter_height = terr.GetHeight(campos) + 0.9;
        //if (campos.y<ter_height) node.position = Vector3(campos.x, ter_height, campos.z);
    }



}

class flyer : ScriptObject
{
	Vector3 vel;
	float ttl = 120;
	void Init(Vector3 invel)
    {
		vel = invel;
	}
	
	void Update(float timeStep)
	{
		node.position += vel*timeStep;
		vel *= 1 - 0.2*timeStep;
		vel += Vector3(1 - Random(2),1 - Random(2),1 - Random(2))*20**timeStep;
		ttl -= timeStep;
		if (ttl<0) node.Remove();
	}
}