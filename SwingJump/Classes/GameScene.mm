//
//  GameScene.mm
//  SwingJump
//
//  Created by Sean Stavropoulos on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MainMenuScene.hh"
#import "SimpleAudioEngine.h"
#import "GameScene.hh"
#import "GFFParallaxNode.h"
#import "RepeatableLayer.h"

#define PTM_RATIO 32

b2World *world;
b2Body* links[numLinks];
float camX;
float camY;
Biped* ragdoll;
b2Body *chainBody;
b2Body* groundBody;
b2DistanceJointDef jointDef;
b2Joint *assJoint1;
b2Joint *assJoint2;
b2Joint *assJoint3;
b2Joint *handJoint1;
b2Joint *handJoint2;
b2Joint *headJoint;
GFFParallaxNode *parallaxNode = [GFFParallaxNode node];


@implementation GameScene
- (id) init {
    self = [super init];
    if (self != nil) {
        //CCSprite * bg = [CCSprite spriteWithFile:@"mainmenu_bg.png"]; //change this to be the level background
        //[bg setPosition:ccp(240, 165)];
        //[self addChild:bg z:0];
        //[self addChild:[GameLayer node] z:1];
		RepeatableLayer *bg = [RepeatableLayer layerWithFile:@"mainmenu_bg.png"];
		[parallaxNode addChild:bg z:0 parallaxRatio:0.0f];
		RepeatableLayer *clouds = [RepeatableLayer layerWithFile:@"cloud.png"];
		[clouds setPosition:ccp(0,120)];
		[parallaxNode addChild:clouds z:0 parallaxRatio:0.5f];
		[self addChild:parallaxNode z:0];
		
        [self addChild:[ControlLayer node] z:1];
        [self addChild:[HUDLayer node] z:2];
    }
    return self;
}
@end

@implementation GameLayer

- (id) init {
    self = [super init];
    if (self != nil) {
        CCSprite *swingSet = [CCSprite spriteWithFile:@"swingset_supports.png"];
        [swingSet setScaleY:1.6];
        [swingSet setPosition:ccp(240,210)];
        [self addChild:swingSet z:4];
		
        //swingChain = [CCSprite spriteWithFile:@"swingchain.png"];
        //[swingChain setAnchorPoint:ccp(0.5,1)];
        //[swingChain setPosition:ccp((swingSet.contentSize.width/2), (swingSet.contentSize.height)-2)];
        //[self addChild:swingChain z:1];
		
        
		//Create a world
		CGSize screenSize = [CCDirector sharedDirector].winSize;
		b2AABB worldAABB;
		float borderSize = 96/PTM_RATIO;
		worldAABB.lowerBound.Set(-10*borderSize, -10*borderSize);
		worldAABB.upperBound.Set(10*screenSize.width/PTM_RATIO+borderSize, 10*screenSize.height/PTM_RATIO+borderSize);
		b2Vec2 gravity(0.0f, -10.0f);
		bool doSleep = true;
		world = new b2World(worldAABB, gravity, doSleep);
        
		world->SetContinuousPhysics(true);
		
		
		GLESDebugDraw *m_debugDraw = new GLESDebugDraw(PTM_RATIO);
		uint32 flags = 0;
		flags += 1	* b2DebugDraw::e_shapeBit;
		//flags += 1	* b2DebugDraw::e_jointBit;
		//flags += 1	* b2DebugDraw::e_controllerBit;
		//flags += 1	* b2DebugDraw::e_coreShapeBit;
		//flags += 1	* b2DebugDraw::e_aabbBit;
		//flags += 1	* b2DebugDraw::e_obbBit;
		//flags += 1	* b2DebugDraw::e_pairBit;
		//flags += 1	* b2DebugDraw::e_centerOfMassBit;
		m_debugDraw->SetFlags(flags);
		world->SetDebugDraw(m_debugDraw);
		
		//Create a ground box
		b2BodyDef groundBodyDef;
		groundBodyDef.position.Set(screenSize.width/PTM_RATIO/2, 1.3f);
		groundBody = world->CreateBody(&groundBodyDef);
		b2PolygonDef groundShapeDef;
		groundShapeDef.SetAsBox(screenSize.width/PTM_RATIO, 1.0f);
		groundBody->CreateShape(&groundShapeDef);
		
        [self createSwingChain:350.0f];
		
		[self schedule:@selector(tick:)];
		
		
		
    }
    return self;
}

-(void) createSwingChain:(float)yPos
{
    CGSize screenSize = [CCDirector sharedDirector].winSize;
    //Create pivot point for swing
    b2BodyDef pivotBodyDef;
    pivotBodyDef.position.Set(screenSize.width/PTM_RATIO/2, (yPos+1.0f)/PTM_RATIO);
    b2Body* pivotBody = world ->CreateBody(&pivotBodyDef);
    b2PolygonDef pivotBodyShapeDef;
    pivotBodyShapeDef.SetAsBox(0.1f,.1f);
    pivotBody->CreateShape(&pivotBodyShapeDef);
    

    //Create chain body and shape
    b2BodyDef chainBodyDef;
    b2CircleDef chainShapeDef;
    b2RevoluteJointDef rj;
	b2DistanceJointDef dj;
    b2Body *link = pivotBody;
    int i;
    for(i = 0; i < numLinks; i++)
    {
        chainBodyDef.position.Set(7.5f,(yPos-(5*i))/PTM_RATIO);
        chainBody = world->CreateBody(&chainBodyDef);
        chainShapeDef.radius = (1.5f/PTM_RATIO);
        chainShapeDef.density =  50.0f;
        chainShapeDef.friction = 0.5f;
        chainShapeDef.restitution = 0.0f;
		chainShapeDef.filter.categoryBits = 0x0000;
        chainBody->CreateShape(&chainShapeDef);
        chainBody->SetMassFromShapes();
        
        /*rj.Initialize(&(*chainBody), &(*link), link->GetPosition());
        rj.enableMotor = true;
		rj.maxMotorTorque = 0.0f;
		rj.motorSpeed = 0.0f;
        world->CreateJoint(&rj);
		*/
		dj.Initialize(&(*chainBody), &(*link), chainBody->GetPosition(),link->GetPosition());
		dj.length = 5.0f/PTM_RATIO;
		world->CreateJoint(&dj);
		
		if (i>2){
			dj.Initialize(&(*chainBody), &(*links[i-3]), chainBody->GetPosition(),links[i-3]->GetPosition());
			dj.length = 15.0f/PTM_RATIO;
			world->CreateJoint(&dj);
		}
		
        link = chainBody;
        links[i] = link;
    }
    b2PolygonDef swingSeat;
    chainBodyDef.position.Set(7.5f,(yPos-(5*i))/PTM_RATIO);
    chainBody = world->CreateBody(&chainBodyDef);
    swingSeat.SetAsBox(0.3f, 0.1f);
    swingSeat.density =  10.0f;
    swingSeat.friction = 0.5f;
    swingSeat.restitution = 0.0f;
    chainBody->CreateShape(&swingSeat);
    chainBody->SetMassFromShapes();
    
    links[numLinks-1] = chainBody;
    
    b2RevoluteJointDef revDef;
    b2PrismaticJointDef prismaticJoint;
    revDef.Initialize(&(*chainBody), &(*link), chainBody->GetPosition());
    revDef.lowerAngle= -0.125f * b2_pi;
    revDef.upperAngle= 0.125f * b2_pi;
    revDef.enableLimit = true;
    world->CreateJoint(&revDef); 

    ragdoll = new Biped(world, b2Vec2(600.0f/PTM_RATIO/2, 220.0f/PTM_RATIO));
	
	jointDef.Initialize(ragdoll->RHand, &(*links[handLink]), ragdoll->RHand->GetPosition(), links[handLink]->GetPosition());
    jointDef.collideConnected = false;
	jointDef.length = 0.1f;
	jointDef.dampingRatio = 1.0f;
	//jointDef.frequencyHz = 1000.0f;
	handJoint1 = world->CreateJoint(&jointDef);  
	
    jointDef.Initialize(ragdoll->LHand, &(*links[handLink]), ragdoll->LHand->GetPosition(), links[handLink]->GetPosition());
    jointDef.collideConnected = false;
	jointDef.length = 0.1f;
	jointDef.dampingRatio = 1.0f;
	//jointDef.frequencyHz = 100.0f;
    handJoint2 = world->CreateJoint(&jointDef); 
	
	jointDef.dampingRatio = 0.0f;
	jointDef.frequencyHz = 0.0f;
	
    b2Vec2 seatPos = links[numLinks-1]->GetPosition();
	b2Vec2 rseatPos = seatPos;
	b2Vec2 lseatPos = seatPos;
	lseatPos.x = seatPos.x - 0.5f;
	rseatPos.x = seatPos.x + 0.4f;
	//seatPos.x = seatPos.x-.2f;
    //seatPos.y = seatPos.y+.01f;

	/*jointDef.Initialize(&(*links[0]), &(*links[numLinks-1]), links[0]->GetPosition(), lseatPos);
    jointDef.collideConnected = false;
	jointDef.length = 5.0*(numLinks*1.016)/PTM_RATIO;
    world->CreateJoint(&jointDef);
	
	jointDef.Initialize(&(*links[0]),&(*links[numLinks-1]), links[0]->GetPosition(), rseatPos);
    jointDef.collideConnected = false;
	jointDef.length = 5.0*(numLinks*1.016)/PTM_RATIO;
    world->CreateJoint(&jointDef);
*/
	jointDef.Initialize(&(*links[0]), &(*links[numLinks-1]), links[0]->GetPosition(), seatPos);
    jointDef.collideConnected = false;
	jointDef.length = 5.0*(numLinks*1.013)/PTM_RATIO;
	//jointDef.frequencyHz = 12.0f;
    world->CreateJoint(&jointDef);
	//jointDef.frequencyHz = 0.0f;
	
	/*jointDef.Initialize(&(*links[numLinks-3]), &(*links[numLinks-1]), links[numLinks-3]->GetPosition(), lseatPos);
    jointDef.collideConnected = false;
	jointDef.length = 15.0f/PTM_RATIO;
    world->CreateJoint(&jointDef);
	
	jointDef.Initialize(&(*links[numLinks-3]), &(*links[numLinks-1]), links[numLinks-3]->GetPosition(), rseatPos);
    jointDef.collideConnected = false;
	jointDef.length = 15.0f/PTM_RATIO;
    world->CreateJoint(&jointDef);
*/
	jointDef.Initialize(&(*links[numLinks-20]), &(*links[numLinks-1]), links[numLinks-20]->GetPosition(), lseatPos);
    jointDef.collideConnected = false;
	jointDef.length = 101.5f/PTM_RATIO;
    world->CreateJoint(&jointDef);
	
	jointDef.Initialize(&(*links[numLinks-20]), &(*links[numLinks-1]), links[numLinks-20]->GetPosition(), rseatPos);
    jointDef.collideConnected = false;
	jointDef.length = 101.5f/PTM_RATIO;
    world->CreateJoint(&jointDef);
	
    jointDef.Initialize(ragdoll->Pelvis, &(*links[numLinks-1]), ragdoll->Pelvis->GetPosition(), lseatPos);
    jointDef.collideConnected = false;
	jointDef.length = 0.023f;
    assJoint1 = world->CreateJoint(&jointDef);
	
	jointDef.Initialize(ragdoll->RThigh, &(*links[numLinks-1]), ragdoll->RThigh->GetPosition(), rseatPos);
    jointDef.collideConnected = false;
	jointDef.length = 0.05f;
	assJoint2 = world->CreateJoint(&jointDef);
	
	jointDef.Initialize(ragdoll->LThigh, &(*links[numLinks-1]), ragdoll->LThigh->GetPosition(), rseatPos);
    jointDef.collideConnected = false;
	jointDef.length = 0.05f;
	assJoint3 = world->CreateJoint(&jointDef);
    
	jointDef.Initialize(ragdoll->Head, &(*links[0]), ragdoll->Head->GetPosition(), links[0]->GetPosition() );
    jointDef.collideConnected = true;
	jointDef.length = headLinkLength;
	//jointDef.frequencyHz = 2.0f;
    headJoint = world->CreateJoint(&jointDef); 
    
    ragdoll->SetSittingLimits();
	
	//b2ContactListener *contactListener;
	//world->SetContactListener(contactListener);
}

-(void) draw{
	[super draw];
	glEnableClientState(GL_VERTEX_ARRAY);
	world->DrawDebugData();
	glDisableClientState(GL_VERTEX_ARRAY);
}

-(void)tick:(ccTime) dt{
	world->Step(dt, 10, 8);
	for(b2Body* b = world->GetBodyList();b;b=b->GetNext())
	{
		if(b->GetUserData()!=NULL)
		{
			CCSprite* ballData = (CCSprite*)b->GetUserData();
			ballData.position = CGPointMake( b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
		}
	}
	b2Vec2 camPos;
	camPos = ragdoll->Head->GetPosition();
	camX = camPos.x;
	camY = camPos.y;
	b2Vec2 vel = ragdoll->Head->GetLinearVelocity();
	[parallaxNode scrollX:vel.x scrollY:-2*vel.y];
	[self.camera setCenterX:camX*PTM_RATIO-80.0f centerY:camY*PTM_RATIO+80.0f centerZ:100.0f];
	[self.camera setEyeX:camX*PTM_RATIO-80.0f eyeY:camY*PTM_RATIO+80.0f eyeZ:415.0f];
	b2XForm groundPos = groundBody->GetXForm();

	groundBody->SetXForm(b2Vec2((camX*PTM_RATIO-80.0f)/PTM_RATIO,groundPos.position.y), 0.0f);
}

@end

@implementation ControlLayer
@synthesize leftArrow;
@synthesize rightArrow;
@synthesize jumpButton;
@synthesize gl;
@synthesize isRightBeingTouched;
@synthesize isLeftBeingTouched;
@synthesize hasJumped;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.isTouchEnabled = YES;
        isRightBeingTouched = NO;
        isLeftBeingTouched = NO;
		hasJumped = NO;
        leftArrow = [CCSprite spriteWithFile:@"circlearrow.png"];
        [leftArrow setPosition:ccp(50,160)];
        [leftArrow setOpacity:128];
        leftArrow.rotation = 180;
        [self addChild:leftArrow z:1];
        rightArrow = [CCSprite spriteWithFile:@"circlearrow.png"];
        [rightArrow setPosition:ccp(430,160)];
        [rightArrow setOpacity:128];
        [self addChild:rightArrow z:1];
        
		jumpButton = [CCSprite spriteWithFile:@"jumpBtn.png"];
		[jumpButton setPosition:ccp(240,270)];
        [jumpButton setOpacity:128];
        [self addChild:jumpButton z:1];
        
        gl = [GameLayer node];
        [self addChild:gl z:0]; //added as a child so touchesEnded can call a function contained in GameLayer
        //gl = [GameLayer node];
    }
    return self;
}

- (BOOL)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
        CGFloat tempX = location.x;
        location.x = location.y;
        location.y = tempX;
        
		if (CGRectContainsPoint([leftArrow boundingBox], location)) {
            //NSLog(@"Left touched");
            if(!isRightBeingTouched && !hasJumped)
            {
                isLeftBeingTouched = YES;
                [leftArrow runAction:[CCFadeTo actionWithDuration:0.2 opacity:255]];
                [self performSelectorInBackground:@selector(rotateChainLeft) withObject:nil];
				ragdoll->PumpBckwdLimits();
			
            }
        }
		if (CGRectContainsPoint([jumpButton boundingBox], location)) {
            //NSLog(@"Left touched");
			if(!hasJumped)
			{
				hasJumped = YES;
				[jumpButton runAction:[CCFadeTo actionWithDuration:0.2 opacity:0]];
				[leftArrow runAction:[CCFadeTo actionWithDuration:0.2 opacity:0]];
				[rightArrow runAction:[CCFadeTo actionWithDuration:0.2 opacity:0]];
				[self performSelectorInBackground:@selector(launch) withObject:nil];
			}
		}
        if (CGRectContainsPoint([rightArrow boundingBox], location)) {
            //NSLog(@"Right touched");
            if(!isLeftBeingTouched && !hasJumped)
            {
                isRightBeingTouched = YES;
                [rightArrow runAction:[CCFadeTo actionWithDuration:0.2 opacity:255]];
                [self performSelectorInBackground:@selector(rotateChainRight) withObject:nil];
				
				ragdoll->PumpFwdLimits();
            } 
        }
	}
	return kEventHandled;
}

- (BOOL)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(isLeftBeingTouched)
    {
        [leftArrow runAction:[CCFadeTo actionWithDuration:0.2 opacity:128]];
        isLeftBeingTouched = NO;
		ragdoll->SetSittingLimits();
    }
    if(isRightBeingTouched)
    {
        [rightArrow runAction:[CCFadeTo actionWithDuration:0.2 opacity:128]];
        isRightBeingTouched = NO;
		ragdoll->SetSittingLimits();
    }
    
	return kEventHandled;
}

- (void)rotateChainLeft
{
    if(isLeftBeingTouched) 
    {
		//for(int i = 0; i < numLinks; i++)
		//{
		links[numLinks-1]->ApplyForce(b2Vec2(-20.0f, 5.0f),links[numLinks-1]->GetPosition());
		//}
		[self runAction:[CCSequence actions:[CCRotateBy actionWithDuration:0.1 angle:0],[CCCallFunc actionWithTarget:self selector:@selector(rotateChainLeft)], nil]];
	
	}    
}

- (void)rotateChainRight
{
    if(isRightBeingTouched) 
    {
		//for(int i = 0; i < numLinks; i++)
		//{
		links[numLinks-1]->ApplyForce(b2Vec2(20.0f, 5.0f),links[numLinks-1]->GetPosition());
		//}
		[self runAction:[CCSequence actions:[CCRotateBy actionWithDuration:0.1 angle:0],[CCCallFunc actionWithTarget:self selector:@selector(rotateChainRight)], nil]];
	}
}
-(void)launch{
    //MainMenuScene * ms = [MainMenuScene node];
	//[[CCDirector sharedDirector] replaceScene: [CCCrossFadeTransition transitionWithDuration:0.5 scene: ms]];
	ragdoll->SetDefaultLimits();
	world->DestroyJoint(headJoint);
	world->DestroyJoint(handJoint1);
	world->DestroyJoint(handJoint2);
	world->DestroyJoint(assJoint1);
	world->DestroyJoint(assJoint2);
	world->DestroyJoint(assJoint3);
	b2Vec2 vel;
	vel = links[numLinks-1]->GetLinearVelocity();
	vel.x = 1.75*vel.x;
	vel.y = 1.75*vel.y;
	ragdoll->SetLinearVelocity(vel);
	
}

@end



@implementation HUDLayer
@synthesize scoreDisplay;

- (id) init {
    self = [super init];
    if (self != nil) {
        [CCMenuItemFont setFontSize:14];
        [CCMenuItemFont setFontName:@"Marker Felt"];
        CCMenuItem *mainmenu = [CCMenuItemFont itemFromString:@"Main Menu"
													target:self
												  selector:@selector(gameSceneBtn:)];
        CCMenuItem *reset = [CCMenuItemFont itemFromString:@"Reset"
                                                       target:self
                                                     selector:@selector(resetBtn:)];
		
        CCMenu *menu = [CCMenu menuWithItems:mainmenu, reset, nil];
        [menu setPosition:ccp(440, 20)];
        [menu alignItemsVerticallyWithPadding:10];
        [self addChild:menu];
        scoreDisplay = [[CCLabelAtlas labelAtlasWithString:@"0" charMapFile:@"fps_images.png" itemWidth:16 itemHeight:24 startCharMap:'.'] retain];
        [scoreDisplay setPosition:ccp(320, 290)];
        [self addChild:scoreDisplay];
		[self schedule:@selector(tick:)];
    }
    
    return self;
}

-(void)gameSceneBtn: (id)sender {
    MainMenuScene * ms = [MainMenuScene node];
	[[CCDirector sharedDirector] replaceScene: [CCCrossFadeTransition transitionWithDuration:0.5 scene: ms]];
}

-(void)resetBtn: (id)sender {
    GameScene *gs = [GameScene node];
	[[CCDirector sharedDirector] replaceScene: [CCCrossFadeTransition transitionWithDuration:0.5 scene: gs]];
}


-(void)tick:(ccTime) dt{
	b2Vec2 headPos = ragdoll->Head->GetPosition();
	NSString *strHeadPos = [NSString stringWithFormat:@"%8.0f",headPos.x];
	//scoreDisplay = [[CCLabelAtlas labelAtlasWithString:strHeadPos charMapFile:@"fps_images.png" itemWidth:16 itemHeight:24 startCharMap:'.'] retain];
	[scoreDisplay setString:strHeadPos];
	[scoreDisplay updateAtlasValues];
}
@end