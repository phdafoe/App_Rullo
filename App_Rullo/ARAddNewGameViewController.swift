//
//  ARAddNewGameViewController.swift
//  App_Rullo
//
//  Created by Andres Ocampo on 15/3/17.
//  Copyright © 2017 Andres Ocampo. All rights reserved.
//

import UIKit
import CoreData

protocol ARAddNewGameViewControllerDelegate {
    func didAddGame()
}



class ARAddNewGameViewController: UIViewController {
    
    
    //MARK: - Varibales locales
    var manageContext : NSManagedObjectContext?
    var arDelegate : ARAddNewGameViewControllerDelegate?
    var game : Game?
    var datePicker : UIDatePicker!
    var dateFormatter = DateFormatter()
    
    
    //MARK: - IBOutlets
    @IBOutlet weak var myImagenGame: UIImageView!
    @IBOutlet weak var mySwitch: UISwitch!
    @IBOutlet weak var myTituloGame: UITextField!
    @IBOutlet weak var myQuienPrestadoGame: UITextField!
    @IBOutlet weak var myCuandoPrestadoGame: UITextField!
    @IBOutlet weak var myEliminarVideojuegoBTN: UIButton!
    
    //MARK: - IBActions
    @IBAction func myEliminiarVideojuegoACTION(_ sender: Any) {
        //Borramos nuestro registro
        if let context = manageContext{
            context.delete(game!)
            game = nil
            //informamos a nuestro delegado que hay que refrescar la pantalla
            arDelegate?.didAddGame()
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    
    @IBAction func mySwitchValueChanged(_ sender: UISwitch) {
        if sender.isOn{
            myQuienPrestadoGame.isEnabled = true
            myCuandoPrestadoGame.isEnabled = true
            myCuandoPrestadoGame.text = dateFormatter.string(from: Date())
        }else{
            myQuienPrestadoGame.isEnabled = false
            myCuandoPrestadoGame.isEnabled = false
            myQuienPrestadoGame.text = ""
            myCuandoPrestadoGame.text = ""
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        //Imagen
        myImagenGame.isUserInteractionEnabled = true
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(pickPhoto))
        myImagenGame.addGestureRecognizer(tapGR)
        
        
        //Teclado
        // a traves de ¡l notificationcenter podemos saber que pasa y como nos avisa a traves de un payload(paquete de informacion)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        //escondemos el teclado
        let tapGRHideKeyboard = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoardWhenUserTappedView))
        self.view.addGestureRecognizer(tapGRHideKeyboard)
        
        //datePickerView
        datePicker = UIDatePicker(frame: CGRect(x: 0, y: 210, width: 320, height: 216))
        datePicker?.datePickerMode = .date
        datePicker?.addTarget(self, action: #selector(datePickerChangedValue(_:)), for: .valueChanged)
        myCuandoPrestadoGame.inputView = datePicker
        
        
        //Dos logicas para este VC / cuando tiene un juego y cuando no tiene un Juego
        //reutilizaremos este VC
        if game == nil{
            self.title = "Añadir Videojuego"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed))
            myEliminarVideojuegoBTN.isHidden = true
            mySwitch.isOn = false
        }else{
            self.title = "Editar Videojuego"
            myTituloGame.text = game?.title
            if let borrowed = game?.borrowed{
                mySwitch.isOn = borrowed
            }
            myQuienPrestadoGame.text = game?.borrowedTo
            if let borrowedDate = game?.borrowedDate as Date?{
                myCuandoPrestadoGame.text = dateFormatter.string(from: borrowedDate)
            }
            
            if let imageData = game?.image as Data?{
                myImagenGame.image = UIImage(data: imageData)
            }
            myEliminarVideojuegoBTN.isHidden = false
        }
        
        if !mySwitch.isOn{
            myQuienPrestadoGame.isEnabled = false
            myCuandoPrestadoGame.isEnabled = false
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if game != nil{
            saveGame()
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - Utils
    //Teclado
    func keyboardWillShow(_ notification : Notification){
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        //vamos a desplazar toda nustra vista hacia rriba cuando el teclado sale en la misma medida y a la misma velocidad
        UIView.animate(withDuration: keyboardTime) { 
            self.view.frame.origin.y = -(keyboardFrame.height)
        }
    }
    
    func keyboardWillHide(_ notification : Notification){
        let info = notification.userInfo!
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        //vamos a desplazar toda nustra vista hacia rriba cuando el teclado sale en la misma medida y a la misma velocidad
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = 0
        }
    }
    
    //ocultar teclado tocando en cualquier parte de la pantalla
    func hideKeyBoardWhenUserTappedView(){
        //hacemos un bucle para controlar y saber cuales objetos son textField
        for c_view in self.view.subviews{
            if let textFiled = c_view as? UITextField{
                textFiled.resignFirstResponder()
            }
        }
    }
    
    func datePickerChangedValue(_ picker : UIDatePicker){
        myCuandoPrestadoGame.text = dateFormatter.string(from: picker.date)
    }
    
    func cancelButtonPressed(){
        dismiss(animated: true, completion: nil)
    }
    
    func saveButtonPressed(){
        saveGame()
        dismiss(animated: true, completion: nil)
    }
    
    func saveGame(){
        //inyectamos el contexto
        if let context = manageContext{
            //1 -> con esta logica lo que conseguimos es trabajar a partir de este punto con editedGame
            var editedGame : Game?
            // 2 tenemos que crear un nuevo objeto
            if game == nil{
                editedGame = Game(context: context)
            }else{
                editedGame = game
            }
            
            if let editedGameDes = editedGame{
                
                editedGameDes.dateCreated = NSDate()
                
                if let title = self.myTituloGame.text{
                    editedGameDes.title = title
                }
                
                editedGameDes.borrowed = self.mySwitch.isOn
                
                if let imageData = myImagenGame.image{
                    editedGameDes.image = UIImagePNGRepresentation(imageData) as NSData?
                }else{
                    editedGameDes.image = NSData()
                }
                
                if editedGameDes.borrowed{
                    if let borrowedTo = myQuienPrestadoGame.text{
                        editedGameDes.borrowedTo = borrowedTo.uppercased() //-> Mayusculas
                    }
                    if let stringDate = myCuandoPrestadoGame.text{
                        editedGameDes.borrowedDate = dateFormatter.date(from: stringDate) as NSDate?
                    }
                }else{
                    editedGameDes.borrowedTo = nil
                    editedGameDes.borrowedDate = nil
                }
                
                //salvar
                do{
                    try context.save()
                    //avisamos al delegado 
                    // esto va a hacer que se ejecute el metodo didAddGame desde la GameViewController si le hemos dicho que implemente ese protocolo
                    self.arDelegate?.didAddGame()
                }catch{
                    print("Error al guadar los datos en CoreData")
                }
            }
        }
    }
    
    

   

}
//MARK: - PICKER PHOTO
extension ARAddNewGameViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func pickPhoto(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            showPhotoMenu()
        }else{
            choosePhotoFromLIbrary()
        }
    }
    
    func showPhotoMenu(){
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAccion = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: {
            Void in self.takePhotoWithCamera()
        })
        let chooseFromLibraryAction = UIAlertAction(title: "Choose from Library", style: .default, handler: {
            Void in self.choosePhotoFromLIbrary()
        })
        alertController.addAction(cancelAccion)
        alertController.addAction(takePhotoAction)
        alertController.addAction(chooseFromLibraryAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    func takePhotoWithCamera(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func choosePhotoFromLIbrary(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageData = info[UIImagePickerControllerEditedImage] as? UIImage{
            myImagenGame.image = imageData
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}
