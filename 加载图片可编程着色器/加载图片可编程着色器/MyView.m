//
//  MyView.m
//  加载图片可编程着色器
//
//  Created by lvAsia on 2020/7/29.
//  Copyright © 2020 yazhou lv. All rights reserved.
//
/*
不采样GLKBaseEffect，使用编译链接自定义的着色器（shader）。用简单的glsl语言来实现顶点、片元着色器，并图形进行简单的变换。
思路：
  1.创建图层
  2.创建上下文
  3.清空缓存区
  4.设置RenderBuffer
  5.设置FrameBuffer
  6.开始绘制

*/
#import "MyView.h"
#import <OpenGLES/ES2/gl.h>
@interface MyView()
@property(nonatomic, strong) CAEAGLLayer  *myEagLayer;
@property(nonatomic, strong) EAGLContext *myContext;
@property(nonatomic, assign) GLuint myColorRenderBuffer;
@property(nonatomic, assign) GLuint myColorFrameBuffer;
@property(nonatomic, assign) GLuint myPrograme;
@end
@implementation MyView

- (void)layoutSubviews{
    //1.设置图层
    [self setUpLayer];
    
    //2.设置图形上下文
    [self setUpContext];
    
    //3.清空缓存区
    [self deleteRenderBufferAndFrameBuffer];

    //4.设置RenderBuffer
    [self setUpRenderBuffer];
    
    //5.设置FrameBuffer
    [self setUpFrameBuffer];
    
    //6.开始绘制
    [self renderLayer];
}


//1. 设置图层

- (void)setUpLayer{
    //创建特殊图层
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    //设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    // 设置描述属性
    NSDictionary *pDcit = @{
        kEAGLDrawablePropertyRetainedBacking:@false,
        kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
        
    };
    self.myEagLayer.drawableProperties = pDcit;

}
+ (Class)layerClass{
    return [CAEAGLLayer class];
}
//2. 设置上下文
- (void)setUpContext{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    if (!context){
        NSLog(@"context create error ");
        return;
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"setCurrentContext failed!");
        return;
    }
    self.myContext = context;
}

//3.清空缓存区

- (void)deleteRenderBufferAndFrameBuffer{
    
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}
//4. 设置renderBuffer
- (void)setUpRenderBuffer{
    
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
}
//5 设置framebuffer
- (void)setUpFrameBuffer{
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    
    self.myColorFrameBuffer = buffer;
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    

}
//6 开始绘制
- (void)renderLayer{
    
    glClearColor(0.3f, 0.45f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    NSString *verfilePath = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
     NSString *fragfilePath = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    self.myPrograme = [self LoadShaders:verfilePath withfrag:fragfilePath];
    glLinkProgram(self.myPrograme);
    GLint linkStatus;
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE){
       GLchar message[1024];
       glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
       NSString *messageString = [NSString stringWithUTF8String:message];
       NSLog(@"Program Link Error:%@",messageString);
       return;
    }
    NSLog(@"Program Link Success!");
    
    glUseProgram(self.myPrograme);
    
    GLfloat attrArr[] =
       {
           0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
           -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
           -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
           
           0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
           -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
           0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
       };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE,  sizeof(GL_FLOAT) * 5, NULL);
    
    
    GLuint textColor = glGetAttribLocation(self.myPrograme, "textCoordinate");
    glEnableVertexAttribArray(textColor);
    glVertexAttribPointer(textColor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float*)NULL + 3);
    
    
    
    [self setupTexture:@"iu.jpg"];
    
    glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);

    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
}

//从图片中加载纹理
- (GLuint)setupTexture:(NSString *)fileName {
    
    //1、将 UIImage 转换为 CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    
    //判断图片是否获取成功
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    //2、读取图片的大小，宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //3.获取图片字节数 宽*高*4（RGBA）
    GLubyte * spriteData = (GLubyte *) calloc(width * height * 4, sizeof(GLubyte));
    
    //4.创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    

    //5、在CGContextRef上--> 将图片绘制出来
    /*
     CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
     CGContextDrawImage
     参数1：绘图上下文
     参数2：rect坐标
     参数3：绘制的图片
     */
    CGRect rect = CGRectMake(0, 0, width, height);
   
    //6.使用默认方式绘制
    CGContextSetTextMatrix(spriteContext, CGAffineTransformIdentity);
    CGContextTranslateCTM(spriteContext, 0, rect.size.height);
    CGContextScaleCTM(spriteContext, 1.0, -1.0);
    CGContextDrawImage(spriteContext, rect, spriteImage);
    //7、画图完毕就释放上下文
    CGContextRelease(spriteContext);
    
    //8、绑定纹理到默认的纹理ID（
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //9.设置纹理属性
    /*
     参数1：纹理维度
     参数2：线性过滤、为s,t坐标设置模式
     参数3：wrapMode,环绕模式
     */
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    
    //10.载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    //11.释放spriteData
    free(spriteData);
    return 0;
}

#pragma mark --加载纹理


#pragma mark --shader
- (GLuint)LoadShaders:(NSString *)vert withfrag:(NSString *)frag{
     
    //1,定义两个着色器对象
    
    GLuint VerShader,fragShader;
    //创建program
    GLuint program = glCreateProgram();
    
    //2.编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self ClangCompileShader:&VerShader type:GL_VERTEX_SHADER file:vert];
    [self ClangCompileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
     //3.创建最终的程序
    glAttachShader(program, VerShader);
    glAttachShader(program, fragShader);
    //4.释放不需要的shader
    glDeleteShader(VerShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)ClangCompileShader:(GLuint *)shader type:(GLenum )type file:(NSString *)file{
    //1.读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar* sourse = (GLchar *)[content UTF8String];
    //2.创建一个shader（根据type类型）
    *shader = glCreateShader(type);
    //3.将着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &sourse, NULL);
   // 4.把着色器源代码编译成目标代码
    glCompileShader(*shader);

    
}
@end
