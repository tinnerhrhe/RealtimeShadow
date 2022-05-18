#ifdef GL_ES
precision mediump float;
#endif

// Phong related variables
uniform sampler2D uSampler;
uniform vec3 uKd;
uniform vec3 uKs;
uniform vec3 uLightPos;
uniform vec3 uCameraPos;
uniform vec3 uLightIntensity;

varying highp vec2 vTextureCoord;
varying highp vec3 vFragPos;
varying highp vec3 vNormal;

// Shadow map related variables
#define NUM_SAMPLES 20
#define BLOCKER_SEARCH_NUM_SAMPLES NUM_SAMPLES
#define PCF_NUM_SAMPLES NUM_SAMPLES
#define NUM_RINGS 10
#define W_LIGHT 1.15
#define ENABLE_2LIGHT
#define EPS 1e-3
#define PI 3.141592653589793
#define PI2 6.283185307179586

uniform sampler2D uShadowMap;
uniform sampler2D uShadowMap2;
varying vec4 vPositionFromLight;
varying vec4 vPositionFromLight2;
highp float rand_1to1(highp float x ) { 
  // -1 -1
  return fract(sin(x)*10000.0);
}

highp float rand_2to1(vec2 uv ) { 
  // 0 - 1
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract(sin(sn) * c);
}

float unpack(vec4 rgbaDepth) {
    const vec4 bitShift = vec4(1.0, 1.0/256.0, 1.0/(256.0*256.0), 1.0/(256.0*256.0*256.0));
    return dot(rgbaDepth, bitShift);
}

vec2 poissonDisk[NUM_SAMPLES];

void poissonDiskSamples( const in vec2 randomSeed ) {

  float ANGLE_STEP = PI2 * float( NUM_RINGS ) / float( NUM_SAMPLES );
  float INV_NUM_SAMPLES = 1.0 / float( NUM_SAMPLES );

  float angle = rand_2to1( randomSeed ) * PI2;
  float radius = INV_NUM_SAMPLES;
  float radiusStep = radius;

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( cos( angle ), sin( angle ) ) * pow( radius, 0.75 );
    radius += radiusStep;
    angle += ANGLE_STEP;
  }
}

void uniformDiskSamples( const in vec2 randomSeed ) {

  float randNum = rand_2to1(randomSeed);
  float sampleX = rand_1to1( randNum ) ;
  float sampleY = rand_1to1( sampleX ) ;

  float angle = sampleX * PI2;
  float radius = sqrt(sampleY);

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( radius * cos(angle) , radius * sin(angle)  );

    sampleX = rand_1to1( sampleY ) ;
    sampleY = rand_1to1( sampleX ) ;

    angle = sampleX * PI2;
    radius = sqrt(sampleY);
  }
}

float findBlocker( sampler2D shadowMap,  vec2 uv, float zReceiver ) {
	poissonDiskSamples(uv);
  //uniformDiskSamples(uv);

  float textureSize = 400.0;

  // define the stride
  float filterStride = 20.0;
  float filterRange = 1.0 / textureSize * filterStride;

  // calculate relative position
  int blockCount = 0;
  float blockDepth = 0.0;
  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    vec2 sampleCoord = poissonDisk[i] * filterRange + uv;
    vec4 depthVec = texture2D(shadowMap, sampleCoord); 
    float depth = unpack(depthVec);
    if(zReceiver > depth + 0.01){
      blockDepth += depth;
      blockCount += 1;
    }
  }

  
  // average
  return blockDepth / float(blockCount);
}

float PCF(sampler2D shadowMap, vec4 coords) {
  //poissonDiskSamples(coords.xy);
  uniformDiskSamples(coords.xy);

  // the size of shadow map filter
  float textureSize = 400.0;
  // define the stride
  float filterStride = 5.0;
  // calculate corresponding range
  float filterRange = 1.0 / textureSize * filterStride;
  // relative shadow position among the range
  int unBlockCount = 0;
  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    vec2 sampleCoord = poissonDisk[i] * filterRange + coords.xy;
    vec4 depthVec = texture2D(shadowMap, sampleCoord); 
    float depth = unpack(depthVec);
    float currentDepth = coords.z;
    if(currentDepth < depth + 0.01){
      unBlockCount += 1;
    }
  }

  float shadow = float(unBlockCount) / float(NUM_SAMPLES);
  return shadow;
}

float PCSS(sampler2D shadowMap, vec4 coords){
  float zReceiver = coords.z;

  // STEP 1: avgblocker depth
  float zBlocker = findBlocker(shadowMap, coords.xy, zReceiver);
  if(zBlocker < EPS) return 1.0;
  if(zBlocker > 1.0) return 0.0;

  // STEP 2: penumbra size
  float wPenumbra = (zReceiver - zBlocker) * W_LIGHT / zBlocker;

  // STEP 3: filtering
  float textureSize = 400.0;
  float filterStride = 5.0;
  float filterRange = 1.0 / textureSize * filterStride * wPenumbra;
  int unBlockCount = 0;
  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    vec2 sampleCoord = poissonDisk[i] * filterRange + coords.xy;
    vec4 depthVec = texture2D(shadowMap, sampleCoord); 
    float depth = unpack(depthVec);
    float currentDepth = coords.z;
    if(currentDepth < depth + 0.01){
      unBlockCount += 1;
    }
  }

  float shadow = float(unBlockCount) / float(NUM_SAMPLES);
  return shadow;
}


float useShadowMap(sampler2D shadowMap, vec4 shadowCoord){
  // get closest depth value from light's perspective (using [0,1] range fragPosLight as coords)
  vec4 depthVec = texture2D(shadowMap, shadowCoord.xy); 
  float depth = unpack(depthVec);
  // get depth of current fragment from light's perspective
  float currentDepth = shadowCoord.z;
  // check whether current frag pos is in shadow
  float bias = max(0.01 * (1.0 - dot(normalize(vNormal), normalize(uLightPos))), 0.005);
  float shadow = depth+bias > currentDepth ? 1.0 : 0.0;
  return shadow;
}

vec3 blinnPhong() {
  vec3 color = texture2D(uSampler, vTextureCoord).rgb;
  color = pow(color, vec3(2.2));

  vec3 ambient = 0.05 * color;

  vec3 lightDir = normalize(uLightPos);
  vec3 normal = normalize(vNormal);
  float diff = max(dot(lightDir, normal), 0.0);
  vec3 light_atten_coff =
      uLightIntensity / pow(length(uLightPos - vFragPos), 2.0);
  vec3 diffuse = diff * light_atten_coff * color;

  vec3 viewDir = normalize(uCameraPos - vFragPos);
  vec3 halfDir = normalize((lightDir + viewDir));
  float spec = pow(max(dot(halfDir, normal), 0.0), 32.0);
  vec3 specular = uKs * light_atten_coff * spec;

  vec3 radiance = (ambient + diffuse + specular);
  vec3 phongColor = pow(radiance, vec3(1.0 / 2.2));
  return phongColor;
}

void main(void) {
  vec3 shadowCoord = vPositionFromLight.xyz / vPositionFromLight.w;
  // 归一化至 [0,1] 
  shadowCoord = shadowCoord * 0.5 + 0.5;
  float visibility, visibility2;
  //visibility = useShadowMap(uShadowMap, vec4(shadowCoord, 1.0));
  //visibility = PCF(uShadowMap, vec4(shadowCoord, 1.0));
  visibility = PCSS(uShadowMap, vec4(shadowCoord, 1.0));
#if defined(ENABLE_2LIGHT)
  vec3 shadowCoord2 = vPositionFromLight2.xyz / vPositionFromLight2.w;
  shadowCoord2 = shadowCoord2 * 0.5 + 0.5;
  //visibility2 = useShadowMap(uShadowMap2, vec4(shadowCoord2, 1.0));
  //visibility2 = PCF(uShadowMap2, vec4(shadowCoord2, 1.0));
  visibility2 = PCSS(uShadowMap2, vec4(shadowCoord2, 1.0));
  visibility = (visibility + visibility2) / 2.0;
#endif
  vec3 phongColor = blinnPhong();

  gl_FragColor = vec4(phongColor * visibility, 1.0);
  //gl_FragColor = vec4(phongColor*visibility, 1.0);
}