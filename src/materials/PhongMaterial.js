class PhongMaterial extends Material {

    constructor(color, specular, light, light2, translate, scale, vertexShader, fragmentShader) {
        let lightMVP = light.CalcLightMVP(translate, scale);
        let lightPos = light.GetLightPos();
        let lightIntensity = light.mat.GetIntensity();
        let lightMVP2 = light2.CalcLightMVP(translate, scale);
        let lightPos2 = light2.GetLightPos();
        let lightIntensity2 = light2.mat.GetIntensity();
        super({
            // Phong
            'uSampler': { type: 'texture', value: color },
            'uKs': { type: '3fv', value: specular },
            'uLightPos': { type: '3fv', value: lightPos },
            'uLightPos2': { type: '3fv', value: lightPos2 },
            'uLightIntensity': { type: '3fv', value: lightIntensity },
            'uLightIntensity2': { type: '3fv', value: lightIntensity2 },
            // Shadow
            'uShadowMap': { type: 'texture', value: light.fbo },
            'uLightMVP': { type: 'matrix4fv', value: lightMVP },
            // Shadow2
            'uShadowMap2': { type: 'texture', value: light2.fbo },
            'uLightMVP2': { type: 'matrix4fv', value: lightMVP2 },

        }, [], vertexShader, fragmentShader);
        this.light = light;
        this.light2 = light2;
    }
    setUniformsParams(pname, nvalue){
        if(pname in this.uniforms){
            this.uniforms[pname].value = nvalue;
        }
    }
}

async function buildPhongMaterial(color, specular, light, light2, translate, scale, vertexPath, fragmentPath) {


    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new PhongMaterial(color, specular, light, light2, translate, scale, vertexShader, fragmentShader);

}