class world : ScriptObject
{
	bool liveUpdate = false;
	String FractalType = "FCTYP_1";
	int steps = 9;
	
	void Init()
	{
		log.Info("IIIINITED!");
	}
	
	void Update(float timeStep)
	{
		if(liveUpdate) UpdateParams();
	}
	
	void UpdateParams()
	{
		//renderer.specularLighting = false;
		RenderPath@ renderpath = renderer.viewports[0].renderPath.Clone();
		
		renderpath.shaderParameters['Iterations'] = Variant(steps);
		
		RenderPathCommand rpc;
				

		for (int i=3; i<7; i++)
		{
			rpc = renderpath.commands[i];
			rpc.pixelShaderDefines = "PREMARCH " + FractalType;
			renderpath.commands[i] = rpc;
		}
		rpc = renderpath.commands[7];
		rpc.pixelShaderDefines = "DEFERRED " + FractalType;
		renderpath.commands[7] = rpc;

		//if (fog) param += " FOG";
		rpc = renderpath.commands[8];
		rpc.pixelShaderDefines = "DEFERRED "  + FractalType;
		renderpath.commands[8] = rpc;

		renderer.viewports[0].renderPath = renderpath;
		
	}
}