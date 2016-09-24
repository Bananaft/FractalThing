class freelookCam : ScriptObject
{
float yaw = 0.0f; // Camera yaw angle
float pitch = 0.0f; // Camera pitch angle
float roll = 0.0f;


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
        float MOVE_SPEED;
        if (input.keyDown[KEY_SHIFT]) MOVE_SPEED = 120.0f; 
		else if (input.keyDown[KEY_CTRL]) MOVE_SPEED = 600.0f; 
		else if (input.keyDown[KEY_ALT]) MOVE_SPEED = 6000.0f; 
		else MOVE_SPEED = 5.0f;
        // Mouse sensitivity as degrees per pixel
        const float MOUSE_SENSITIVITY = 0.1 * 1/cam.zoom;

        // Read WASD keys and move the camera scene node to the corresponding direction if they are pressed
        if (input.keyDown['W'])
            node.Translate(Vector3(0.0f, 0.0f, 1.0f) * MOVE_SPEED * timeStep);
        if (input.keyDown['S'])
            node.Translate(Vector3(0.0f, 0.0f, -1.0f) * MOVE_SPEED * timeStep);
        if (input.keyDown['A'])
            node.Translate(Vector3(-1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
        if (input.keyDown['D'])
            node.Translate(Vector3(1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
        if (input.keyDown['Q'])
            roll += 45 * timeStep;
        else
            roll = 0.0;
			
		if (input.keyDown['R'])
           node.position = Vector3(0.,0.,0.);



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

void FixedUpdate(float timeStep)
	{

    }

}
