#import <Foundation/Foundation.h>
#import "MasterViewController.h"
#import "AddressBookViewController.h"
#import "RegisterViewController.h"
#import "NIKApiInvoker.h"
#import "CustomNavBar.h"
#import "AppDelegate.h"

@interface MasterViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)RegisterActionEvent:(id)sender;

- (IBAction)SubmitActionEvent:(id)sender;

@end

@implementation MasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // check if login credentials are already stored
    NSString  *baseDSPUrl=[[NSUserDefaults standardUserDefaults] valueForKey:kBaseDspUrl];
    NSString  *userEmail=[[NSUserDefaults standardUserDefaults] valueForKey:kUserEmail];
    NSString  *userPassword=[[NSUserDefaults standardUserDefaults] valueForKey:kPassword];
    
    [self.emailTextField setValue:[UIColor colorWithRed:180/255.0 green:180/255.0 blue:180/255.0 alpha:1.0] forKeyPath:@"_placeholderLabel.textColor"];
    [self.passwordTextField setValue:[UIColor colorWithRed:180/255.0 green:180/255.0 blue:180/255.0 alpha:1.0] forKeyPath:@"_placeholderLabel.textColor"];
    
    if(userEmail.length >0 && userPassword.length >0 && baseDSPUrl.length>0){
        [self.emailTextField setText:userEmail];
        [self.passwordTextField setText:userPassword];
    }
    
    // set up the custom nav bar
    AppDelegate* bar = [[UIApplication sharedApplication] delegate];
    CustomNavBar* navBar = bar.globalToolBar;
    [navBar.backButton addTarget:self action:@selector(hitBackButton) forControlEvents:UIControlEventTouchDown];    
}

- (void) hitBackButton{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    AppDelegate* bar = [[UIApplication sharedApplication] delegate];
    CustomNavBar* navBar = bar.globalToolBar;
    [navBar showBackButton:NO];
    [navBar showAddButton:NO];
    [navBar showEditButton:NO];
    [navBar showDoneButton:NO];
    [navBar reloadInputViews];
}

- (IBAction)RegisterActionEvent:(id)sender {
    [self showRegisterViewController];
}

- (void) other:(  NSString*) path
        method: (  NSString*) method
   queryParams: (  NSDictionary*) queryParams
          body: (   id) body
  headerParams: ( NSDictionary*) headerParams
   contentType: ( NSString*) contentType
completionBlock: (void (^)(NSDictionary*, NSError *))completionBlock {
    
    
}
- (IBAction)SubmitActionEvent:(id)sender {
    // log in using the generic API
    if(self.emailTextField.text.length>0 && self.passwordTextField.text.length>0) {
        [self.emailTextField resignFirstResponder];
        [self.passwordTextField resignFirstResponder];
        
        // use the generic API invoker
        NIKApiInvoker *_api = [NIKApiInvoker sharedInstance];
        NSString *baseUrl = kBaseDspUrl; // <DSP url>/rest
        
        // build rest path for request, form is <url to DSP>/rest/serviceName/tableName
        NSString *serviceName = @"user"; // your service name here
        NSString *tableName = @"session"; // rest path
        NSString *restApiPath = [NSString stringWithFormat:@"%@/%@/%@",baseUrl,serviceName, tableName];
        NSLog(@"\n%@\n", restApiPath);
        
        NSMutableDictionary* queryParams = [[NSMutableDictionary alloc] init];
        
        // header has session id and application name to validate access
        NSMutableDictionary* headerParams = [[NSMutableDictionary alloc] init];
        [headerParams setObject:kApplicationName forKey:@"X-DreamFactory-Application-Name"];
        
        NSString* contentType = @"application/json";
        NSDictionary* requestBody = @{@"email":self.emailTextField.text,
                                      @"password":self.passwordTextField.text};
        __weak id weakSelf = self;
        [_api restPath:restApiPath
                method:@"POST"
           queryParams:queryParams
                  body:requestBody
          headerParams:headerParams
           contentType:contentType
       completionBlock: ^(NSDictionary *responseDict, NSError  *error) {
           MasterViewController* strongSelf = weakSelf;
           NSLog(@"Error registering new user data: %@",error);
           if (error) {
               dispatch_async(dispatch_get_main_queue(),^ (void){
                   UIAlertView *message=[[UIAlertView alloc]initWithTitle:@"" message:@"Error, invalid password" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil];
                   [message show];
               });
           }
           else{
               [[NSUserDefaults standardUserDefaults] setValue:baseUrl forKey:kBaseDspUrl];
               [[NSUserDefaults standardUserDefaults] setValue:[responseDict objectForKey:@"session_id"] forKey:kSessionIdKey];
               [[NSUserDefaults standardUserDefaults] setValue:strongSelf.emailTextField.text forKey:kUserEmail];
               [[NSUserDefaults standardUserDefaults] setValue:strongSelf.passwordTextField.text forKey:kPassword];
               [[NSUserDefaults standardUserDefaults] synchronize];
               
               dispatch_async(dispatch_get_main_queue(),^ (void){
                   [strongSelf showAddressBookViewController];
               });
           }
       }];
    }
    else {
        UIAlertView *message=[[UIAlertView alloc]initWithTitle:@"" message:@"Error, invalid password" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil];
        [message show];
    }
}

- (void) showAddressBookViewController {
    AddressBookViewController* addressBookViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AddressBookViewController"];
    [self.navigationController pushViewController:addressBookViewController animated:YES];
}

- (void) showRegisterViewController {
    RegisterViewController* registerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RegisterViewController"];
    [self.navigationController pushViewController:registerViewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end