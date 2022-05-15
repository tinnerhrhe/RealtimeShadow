class PhongMaterial extends Material {

    constructor(color, specular, lights, translate, scale, vertexShader, fragmentShader) {

        let uniforms = {
            'uSampler': { type: 'texture', value: color },
            'uKs': { type: '3fv', value: specular }
        }

        for (var i in lights){
            uniforms['uLightIntensitys[' + i + ']'] = lights[i].mat.GetIntensity();
            uniforms['uShadowMaps[' + i + ']'] = lights[i].fbo;
            uniforms['uLightMVPs[' + i + ']'] = lights[i].CalcLightMVP(translate, scale)
        }

        super(uniforms, [], vertexShader, fragmentShader);
    }
}

async function buildPhongMaterial(color, specular, lights, translate, scale, vertexPath, fragmentPath) {


    let vertexShader = await getShaderString(vertexPath);
    let fragmentShader = await getShaderString(fragmentPath);

    return new PhongMaterial(color, specular, lights, translate, scale, vertexShader, fragmentShader);

}