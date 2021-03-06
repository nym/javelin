/*

  Copyright (C) 2012 John McCutchan <john@johnmccutchan.com>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

*/

class JavelinFlyingSphere {
  final num radius;
  final DebugDrawManager debugDrawManager;
  vec3 center;
  vec3 velocity;
  vec4 color;

  JavelinFlyingSphere(this.radius, this.debugDrawManager) {
    center = new vec3.zero();
    velocity = new vec3.zero();
    color = new vec4.raw(0.5, 0.5, 0.5, 1.0);
  }

  void reset(vec3 center_, vec3 velocity_) {
    center.copyFrom(center_);
    velocity.copyFrom(velocity_);
  }

  void update() {
    vec3 acceleration = new vec3.raw(0.0, -10.0, 0.0);
    acceleration.scale(0.016);
    velocity.add(acceleration);
    vec3 temp = new vec3.copy(velocity);
    temp.scale(0.016);
    center.add(temp);
  }

  void draw() {
    debugDrawManager.addSphere(center, radius, color, 0.0, true);
  }
}

class JavelinClothDemo extends JavelinBaseDemo {
  int _particlesVBOHandle;
  int _particleIBHandle;
  int _particlesVSResourceHandle;
  int _particlesFSResourceHandle;
  int _particlesVSHandle;
  int _particlesFSHandle;
  int _particlesInputLayoutHandle;
  int _particlesShaderProgramHandle;
  int _particlePointSpriteResourceHandle;
  int _particlePointSpriteHandle;
  int _particlePointSpriteSamplerHandle;
  int _particleDepthStateHandle;
  int _particleBlendStateHandle;
  int _particleRasterizerStateHandle;

  JavelinFlyingSphere _sphere;

  Float32Array _particlesVertexData;

  ClothSystemBackendDVM _particles;

  int _gridWidth;
  int _numParticles;
  int _particleVertexSize;

  JavelinClothDemo(Element element, GraphicsDevice device, ResourceManager resourceManager, DebugDrawManager debugDrawManager) : super(element, device, resourceManager, debugDrawManager) {
    _sphere = new JavelinFlyingSphere(1.0, debugDrawManager);
    _gridWidth = 15;
    _numParticles = _gridWidth*_gridWidth;
    _particleVertexSize = 8;
    _particles = new ClothSystemBackendDVM(_gridWidth);
    // Position+Color+TC
    _particlesVertexData = new Float32Array(_numParticles*_particleVertexSize);
    for (int i = 0; i < _gridWidth; i++) {
      for (int j = 0; j < _gridWidth; j++) {
        int index = (i + j * _gridWidth) * _particleVertexSize;
        _particlesVertexData[index+0] = 0.0;
        _particlesVertexData[index+1] = 0.0;
        _particlesVertexData[index+2] = 0.0;
        // Color
        _particlesVertexData[index+3] = 1.0;
        _particlesVertexData[index+4] = 0.0;
        _particlesVertexData[index+5] = 0.0;
        if (i + j * _gridWidth > ((_numParticles ~/ 3) * 2)) {
          _particlesVertexData[index+3] = 0.0;
          _particlesVertexData[index+4] = 0.0;
          _particlesVertexData[index+5] = 1.0;
        } else if (i + j * _gridWidth > (_numParticles ~/ 3)) {
          _particlesVertexData[index+3] = 0.0;
          _particlesVertexData[index+4] = 1.0;
          _particlesVertexData[index+5] = 0.0;
        }
        _particlesVertexData[index+6] = i / _gridWidth;
        _particlesVertexData[index+7] = j / _gridWidth;
      }
    }
  }

  Future<JavelinDemoStatus> startup() {
    Future<JavelinDemoStatus> base = super.startup();

    _particleIBHandle = device.createIndexBuffer('Cloth Index Buffer', {'usage':'static', 'size':2*(_gridWidth-1)*(_gridWidth-1)*6});

    {
      Uint16Array indexArray = new Uint16Array((_gridWidth-1)*(_gridWidth-1)*6);
      int out = 0;
      for (int i = 0; i < _gridWidth-1; i++) {
        for (int j = 0; j < _gridWidth-1; j++) {
          int northWest = i + j * _gridWidth;
          int northEast = (i+1) + j * _gridWidth;
          int southWest = i + (j+1)*_gridWidth;
          int southEast = (i+1) + (j+1)*_gridWidth;
          indexArray[out++] = northWest;
          indexArray[out++] = northEast;
          indexArray[out++] = southWest;
          indexArray[out++] = southWest;
          indexArray[out++] = northEast;
          indexArray[out++] = southEast;
        }
      }
      immediateContext.updateBuffer(_particleIBHandle, indexArray);
    }

    _particlesVBOHandle = device.createVertexBuffer('Cloth Vertex Buffer', {'usage':'stream', 'size':_numParticles*_particleVertexSize});
    _particlesVSResourceHandle = resourceManager.registerResource('/shaders/simple_cloth.vs');
    _particlesFSResourceHandle = resourceManager.registerResource('/shaders/simple_cloth.fs');
    _particlesVSHandle = device.createVertexShader('Cloth Vertex Shader',{});
    _particlesFSHandle = device.createFragmentShader('Cloth Fragment Shader', {});
    _particlePointSpriteResourceHandle = resourceManager.registerResource('/textures/felt.png');
    _particlePointSpriteHandle = device.createTexture2D('Cloth Texture', { 'width': 128, 'height': 128, 'textureFormat' : Texture.TextureFormatRGBA, 'pixelFormat': Texture.PixelFormatUnsignedByte});
    _particlePointSpriteSamplerHandle = device.createSamplerState('Cloth Sampler', {'wrapS':SamplerState.TextureWrapClampToEdge, 'wrapT':SamplerState.TextureWrapClampToEdge,'minFilter':SamplerState.TextureMagFilterNearest,'magFilter':SamplerState.TextureMagFilterLinear});
    _particleDepthStateHandle = device.createDepthState('Cloth Depth State', {'depthTestEnabled': true, 'depthWriteEnabled': true, 'depthComparisonOp': DepthState.DepthComparisonOpLessEqual});
    _particleBlendStateHandle = device.createBlendState('Cloth Blend State', {'blendEnable':true, 'blendSourceColorFunc': BlendState.BlendSourceShaderAlpha, 'blendDestColorFunc': BlendState.BlendSourceShaderInverseAlpha, 'blendSourceAlphaFunc': BlendState.BlendSourceShaderAlpha, 'blendDestAlphaFunc': BlendState.BlendSourceShaderInverseAlpha});
    _particleRasterizerStateHandle = device.createRasterizerState('Cloth Rasterizer State', {'cullEnabled':false});
    List loadedResources = [];
    base.then((value) {
      // Once the base is done, we load our resources
      loadedResources.add(resourceManager.loadResource(_particlesVSResourceHandle));
      loadedResources.add(resourceManager.loadResource(_particlesFSResourceHandle));
      loadedResources.add(resourceManager.loadResource(_particlePointSpriteResourceHandle));
    });

    Future allLoaded = Futures.wait(loadedResources);
    Completer<JavelinDemoStatus> complete = new Completer<JavelinDemoStatus>();
    allLoaded.then((list) {
      immediateContext.compileShaderFromResource(_particlesVSHandle, _particlesVSResourceHandle, resourceManager);
      immediateContext.compileShaderFromResource(_particlesFSHandle, _particlesFSResourceHandle, resourceManager);
      _particlesShaderProgramHandle = device.createShaderProgram('Cloth Shader Program', { 'VertexProgram': _particlesVSHandle, 'FragmentProgram': _particlesFSHandle});
      int vertexStride = _particleVertexSize*4;
      var elements = [new InputElementDescription('vPosition', GraphicsDevice.DeviceFormatFloat3, vertexStride, 0, 0),
                      new InputElementDescription('vColor', GraphicsDevice.DeviceFormatFloat3, vertexStride, 0, 12),
                      new InputElementDescription('vTexCoord', GraphicsDevice.DeviceFormatFloat2, vertexStride, 0, 24)];
      _particlesInputLayoutHandle = device.createInputLayout('Cloth Input Layout', {'elements':elements, 'shaderProgram':_particlesShaderProgramHandle});
      immediateContext.updateTexture2DFromResource(_particlePointSpriteHandle, _particlePointSpriteResourceHandle, resourceManager);
      immediateContext.generateMipmap(_particlePointSpriteHandle);
      complete.complete(new JavelinDemoStatus(JavelinDemoStatus.DemoStatusOKAY, ''));
    });
    return complete.future;
  }

  Future<JavelinDemoStatus> shutdown() {
    Future<JavelinDemoStatus> base = super.shutdown();
    _particlesVertexData = null;
    resourceManager.batchDeregister([_particlesVSResourceHandle,
                                     _particlesFSResourceHandle,
                                     _particlePointSpriteResourceHandle]);
    device.batchDeleteDeviceChildren([_particlesVBOHandle,
                                      _particleIBHandle,
                                      _particlesShaderProgramHandle,
                                      _particlesVSHandle,
                                      _particlesFSHandle,
                                      _particlesInputLayoutHandle,
                                      _particlePointSpriteHandle,
                                      _particleDepthStateHandle,
                                      _particlePointSpriteSamplerHandle,
                                      _particleBlendStateHandle,
                                      _particleRasterizerStateHandle]);
    return base;
  }

  void updateParticles() {
    device.context.updateBuffer(_particlesVBOHandle, _particlesVertexData);
  }

  void drawParticles() {
    device.context.setInputLayout(_particlesInputLayoutHandle);
    device.context.setVertexBuffers(0, [_particlesVBOHandle]);
    device.context.setIndexBuffer(_particleIBHandle);
    device.context.setDepthState(_particleDepthStateHandle);
    device.context.setBlendState(_particleBlendStateHandle);
    device.context.setRasterizerState(_particleRasterizerStateHandle);
    device.context.setPrimitiveTopology(GraphicsContext.PrimitiveTopologyTriangles);
    device.context.setShaderProgram(_particlesShaderProgramHandle);
    device.context.setTextures(0, [_particlePointSpriteHandle]);
    device.context.setSamplers(0, [_particlePointSpriteSamplerHandle]);
    device.context.setUniformMatrix4('projectionViewTransform', projectionViewTransform);
    device.context.setUniformMatrix4('projectionTransform', projectionTransform);
    device.context.setUniformMatrix4('viewTransform', viewTransform);
    device.context.setUniformMatrix4('normalTransform', normalTransform);
    //device.immediateContext.draw(_numParticles, 0);
    device.context.drawIndexed((_gridWidth-1)*(_gridWidth-1)*6, 0);
  }

  void mouseButtonEventHandler(MouseEvent event, bool down) {
    super.mouseButtonEventHandler(event, down);
    if (event.button == JavelinMouseButtonCodes.MouseButtonLeft && down) {
      _sphere.reset(camera.position,camera.frontDirection.scale(20.0));
    }
  }

  void update(num time, num dt) {
    Profiler.enter('Demo Update');
    Profiler.enter('super.update');
    super.update(time, dt);
    Profiler.exit(); // Super.update

    {
      quat q = new quat.axisAngle(new vec3.raw(0.0, 0.0, 1.0), 0.0174532925);
      //q.rotate(_particles.gravityDirection);
    }
    Profiler.enter('particles update');
    _particles.sphereConstraints(_sphere.center, _sphere.radius);
    _particles.update();
    _particles.copyPositions(_particlesVertexData, _particleVertexSize);
    updateParticles();

    if (keyboard.pressed(JavelinKeyCodes.KeyZ)) {
      _particles.pick(3, 8, new vec3.raw(0.0, 0.0, 0.0));
    }
    Profiler.exit();

    Profiler.exit(); // Demo update

    drawGrid(20);
    _sphere.update();
    _sphere.draw();
    debugDrawManager.prepareForRender();
    debugDrawManager.render(camera);

    Profiler.enter('Demo draw');
    drawParticles();
    Profiler.exit();

  }
}
