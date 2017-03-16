//
//  ARGamesListCollectionViewController.swift
//  App_Rullo
//
//  Created by Andres Ocampo on 15/3/17.
//  Copyright © 2017 Andres Ocampo. All rights reserved.
//

import UIKit
import CoreData


class ARGamesListCollectionViewController: UIViewController{
    
    //MARK: - Variables locales
    //TODO: - Fase 1 -> Conexion con el manageObjectContext
    var manageContext : NSManagedObjectContext?
    //TODO: - Fase 2 - 3 -> Cracion del listado de objetos Game
    var listGames = [Game]()
    
    
    //MARK: - IBOutlets
    @IBOutlet weak var myFilterSegmentController: UISegmentedControl!
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    //MARK: - Fase 8 -> Filtro del segment control a traves de una action
    // se hace esto para que cuando realicemos el filtro de los videojuegos prestados a todos debemos realizar nuevamente la consulta
    @IBAction func filterChangeACTION(_ sender: UISegmentedControl) {
        performGamesQuery()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        myCollectionView.alwaysBounceVertical = true
        
    }
    
    //TODO: Fase 8 ->
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performGamesQuery()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    
    //MARK: - Utils
    //TODO: Fase 4 - AttributedString -> texto enriquecido
    //con este metodo lo que vamos a hacer es que le pasamos una cadena y a traves del metodo indexOf buscara los : y le pasamos un color y va a colorear a partir de los :
    func formatColors (_ myString : String, myColor : UIColor) -> NSMutableAttributedString{
        //1 -> longitud de "myString" contamos los caracteres que tiene
        let length = myString.characters.count
        //2 -> posicion de los :
        let colonPosition = myString.indexOf(":")!
        
        //3 -> creamos la instancia "NSMutableAttributedString" en ese constructor le pasamos myString
        let myMutableString = NSMutableAttributedString(string: myString, attributes: nil)
        //4 -> hacemos el formato de myMutableString -> se hace añadiendole atributos
            //1 -> primer parametro -> cambiar el color del texto
            //2 -> le pasamos como valor el color que tengamos
            //3 -> le pasamos el rango
        myMutableString.addAttribute(NSForegroundColorAttributeName,
                                     value: myColor,
                                     range: NSRange(location: 0,
                                                    length: length))
            //4 -> segun la posicion de los : mas un caracter a partir de ahi
        myMutableString.addAttribute(NSForegroundColorAttributeName,
                                     value: UIColor.black,
                                     range: NSRange(location: 0,
                                                    length: colonPosition + 1))
        return myMutableString
    }
    
    //TODO: -  Fase 7 -> consulta a CoreData
    func performGamesQuery(){
        //1 -> request
        let customRequest : NSFetchRequest<Game> = Game.fetchRequest()
        //2 -> campo auditoria (dateCreated) consultamos la informacion de forma ordenada
        // key es el campo por el que queremos ordenar
        let sortByDate = NSSortDescriptor(key: "dateCreated", ascending: false)
        //3
        customRequest.sortDescriptors = [sortByDate]
        //4
        if myFilterSegmentController.selectedSegmentIndex == 0{
            //5 -> Creamos un predicado para filtrar los registros // aqui va como un seudo lenguaje a sql
            let customPredicate = NSPredicate(format: "borrowed = true")
            customRequest.predicate = customPredicate
        }
        //6
        do{
            let fetchGames = try manageContext?.fetch(customRequest)
            if let fetchGamesDes = fetchGames{
                listGames = fetchGamesDes
                self.myCollectionView?.reloadData()
            }
        }catch{
            print("Error recuperando datos de CoreData")
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addGameSegue"{
            let navVC = segue.destination as! UINavigationController
            let detalleVC = navVC.topViewController as! ARAddNewGameViewController
            //set el contexto
            detalleVC.manageContext = manageContext
            detalleVC.arDelegate = self
        }
        
        if segue.identifier == "editGameSegue"{
            
            let detalleVC = segue.destination as! ARAddNewGameViewController
            //set el contexto
            detalleVC.manageContext = manageContext
            let selectIndex = myCollectionView.indexPathsForSelectedItems?.first?.row
            let gameInd = listGames[selectIndex!]
            detalleVC.game = gameInd
            detalleVC.arDelegate = self
            
            
        }
        
    }
    
    

    

}//TODO: - Fin de la clase

extension ARGamesListCollectionViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        //TODO: - Fase 5 ->
        //Comrobamos si la lista de juegos es 0 creamos una imagen de fondo de instruccion
        if listGames.count == 0{
            let imageBackgroundList = UIImageView(image: #imageLiteral(resourceName: "img_empty_list"))
            imageBackgroundList.contentMode = .scaleAspectFit
            myCollectionView.backgroundView = imageBackgroundList
        }else{
            myCollectionView.backgroundView = UIView()
        }
        //Siempre retornamos el listado de Juegos .count
        return listGames.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let customCell = myCollectionView.dequeueReusableCell(withReuseIdentifier: "GameDetailCustomCell", for: indexPath) as! ARGameDetailCustomCell
        
        
        //TODO: - Fase 5 ->
        let gameModel = listGames[indexPath.row]
        
        customCell.myNameGame.text = gameModel.title
        
        //definimos los colores
        var myColorPrestado = CONSTANTES.COLORES.COLOR_ROJO
        
        //Vamos a comprobar si esta o no prestado
        if !gameModel.borrowed{
            myColorPrestado = CONSTANTES.COLORES.COLOR_AZUL
        }
        
        //Alimentamos la celda
        customCell.myBorrowedLBL.attributedText = formatColors("PRESTADO: \(gameModel.borrowed ? "SI" : "NO")", myColor: myColorPrestado)
        
        if let borrowedTo = gameModel.borrowedTo{
            customCell.myBorrowedToLBL.attributedText = formatColors("A: \(borrowedTo)", myColor: myColorPrestado)
        }else{
            customCell.myBorrowedToLBL.attributedText = formatColors("A: --", myColor: myColorPrestado)
        }
        
        
        if let borrowedDate = gameModel.borrowedDate as? Date{
            let myDateFormater = DateFormatter()
            myDateFormater.dateFormat = "dd/MM/yyyy"
            myDateFormater.string(from: borrowedDate)
            
            customCell.myBorrowedDateLBL.attributedText = formatColors("FECHA: \( myDateFormater.string(from: borrowedDate))", myColor: myColorPrestado)
        }else{
            customCell.myBorrowedDateLBL.attributedText = formatColors("FECHA: --", myColor: myColorPrestado)
        }
        
        if let imageGame = gameModel.image as? Data{
            customCell.myImageGame.image = UIImage(data: imageGame)
        }
        
        
        //Ajuste de sombra de la celda
        //1 en false no queremos que envuelva hasta los bordes
        customCell.layer.masksToBounds = false
        customCell.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        customCell.layer.shadowColor = CONSTANTES.COLORES.GRIS_BARRA_NAV.cgColor
        customCell.layer.shadowRadius = 2.0
        customCell.layer.shadowOpacity = 0.2
        
        
        // Configure the cell
        
        return customCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //MARK: - FASE 9 -> segues que muestren una vista u otra en el caso de añadir o editar
        performSegue(withIdentifier: "editGameSegue", sender: self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //MARK: - FASE 9 -> segues que muestren una vista u otra en el caso de añadir o editar
        //guardamos un offset / equidistancia entre el borde superior hasta el punto que estamos arrastrando
        //ademas usamos este metodo scroll por que una tabla y una coleccion es una subclase de scrollView
        let offsetY = scrollView.contentOffset.y
        if (offsetY < -120){
            performSegue(withIdentifier: "addGameSegue", sender: self)
        }
    }
    
    
    
    
}





//MARK: - FASE 6 -> Truco delegado
extension ARGamesListCollectionViewController : UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //definimos el tamaños de la celda
        //el ancho total de la celda - ambos margenes
        return CGSize(width: self.view.frame.size.width - 16, height: 400.0)
    }
    
    
}


//MARK: - FASE 4 -> Ajustes de los string (attributeString)
extension String{
    //Creamos una funcion para que podamos manipular nuestros string como un texto enriquecido asi podemos gestionar un "caracter especial por ejemplo " : / ( )" -> podria no devolver nada si no lo encuentra por eso le pasamos un opcional al Int de retorno
    //el self se refiere a la cadena a la que estamos ejecutando e indexOf
    
    //si encontramos dentro del rango el target (caracter)
    //retornamos la posicion con un metodo de calculo de la distancia de que posicion a que posicion aqui es fundamental entender que lo que necesito pillar como fin de la cadena seran : a partir de ese punto puedo colorear el resto de caracteres con el metodo lowerBound -> límite inferior
    func indexOf (_ myTarget : String) -> Int?{
        if let myRange = self.range(of: myTarget){
                return distance(from: self.startIndex, to: myRange.lowerBound)
        }
        return nil
    }
    
}

//TODO: - FASE FINAL DELEGADO DE LA VC
extension ARGamesListCollectionViewController : ARAddNewGameViewControllerDelegate{
    //Cuando haya un didAddgame
    func didAddGame() {
        myCollectionView.reloadData()
    }
    
}






