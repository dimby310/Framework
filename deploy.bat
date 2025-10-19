@echo off
REM === Configuration Java OBLIGATOIRE ===
set JAVA_HOME=C:\Programmes\Java\jdk-17
set JRE_HOME=%JAVA_HOME%
set PATH=%JAVA_HOME%\bin;%PATH%

REM ==================================================
REM   DÉPLOIEMENT COMPLET - MVC FRAMEWORK
REM ==================================================
setlocal EnableDelayedExpansion

REM === Configurations ===
set TOMCAT_PATH=C:\Users\Dimby\Downloads\tomcat-10.1.28-windows-x64\apache-tomcat-10.1.28
set WAR_NAME=TestFramework
set PROJECT_DIR=%~dp0
set FRAMEWORK_DIR=%PROJECT_DIR%Framework_S5
set TEST_DIR=%PROJECT_DIR%testFramework_S5

color 0A
echo.
echo ==================================================
echo    DÉPLOIEMENT COMPLET - MVC FRAMEWORK
echo ==================================================
echo.
echo 🔧 Configuration Java:
echo    JAVA_HOME: %JAVA_HOME%
echo    JRE_HOME:  %JRE_HOME%
echo.

REM === Vérification de Tomcat ===
echo 🔍 Vérification de Tomcat...
if not exist "%TOMCAT_PATH%\bin\startup.bat" (
    echo ❌ ERREUR : Tomcat non trouvé à l'emplacement: %TOMCAT_PATH%
    echo.
    echo 💡 Modifiez la variable TOMCAT_PATH dans ce fichier .bat
    echo.
    pause
    exit /b 1
)

REM === Vérification de Java ===
echo 🔍 Vérification de Java...
java -version >nul 2>&1
if errorlevel 1 (
    echo ❌ ERREUR : Java non accessible. Vérifiez JAVA_HOME
    echo 💡 JAVA_HOME actuel: %JAVA_HOME%
    pause
    exit /b 1
)
echo ✅ Java correctement configuré

REM === Étape 1: Builder le Framework ===
echo.
echo 🔨 ÉTAPE 1: Construction du Framework...
cd /d "%FRAMEWORK_DIR%"

REM Variables pour la librairie FrontServlet
set APP_NAME=FrameworkServlet
set SRC_DIR=src\main\java
set BUILD_DIR=build
set LIB_DIR=lib
set SERVLET_API_JAR=%LIB_DIR%\servlet-api.jar
set TEST_LIB_DIR=..\testFramework_S5\lib

REM Nettoyage
if exist %BUILD_DIR% (
    rmdir /s /q %BUILD_DIR%
)
mkdir %BUILD_DIR%

REM Compilation
echo Compilation de la librairie FrontServlet...
dir /b /s %SRC_DIR%\*.java > sources.txt
javac -cp "%SERVLET_API_JAR%" -d %BUILD_DIR% @sources.txt
if errorlevel 1 (
    echo Erreur de compilation!
    del sources.txt
    pause
    exit /b 1
)
del sources.txt

REM Création du JAR
echo Creation du JAR %APP_NAME%.jar...
cd %BUILD_DIR%
jar -cvf %APP_NAME%.jar com
cd ..

REM Copie vers le projet Test
if not exist %TEST_LIB_DIR% (
    mkdir %TEST_LIB_DIR%
)
copy /Y %BUILD_DIR%\%APP_NAME%.jar %TEST_LIB_DIR%\

echo ✅ Framework construit avec succès!

REM === Étape 2: Builder l'Application de Test ===
echo.
echo 🌐 ÉTAPE 2: Construction de l'application de test...
cd /d "%TEST_DIR%"

REM Variables pour l'application de test
set APP_NAME=%WAR_NAME%
set SRC_DIR=src\main\java
set WEB_DIR=src\main\webapp
set BUILD_DIR=build
set LIB_DIR=lib
set SERVLET_API_JAR=%LIB_DIR%\servlet-api.jar
set FRONT_SERVLET_JAR=%LIB_DIR%\FrameworkServlet.jar

REM Vérifier que la librairie FrontServlet existe
if not exist %FRONT_SERVLET_JAR% (
    echo Erreur: %FRONT_SERVLET_JAR% n'existe pas!
    echo Executez d'abord la construction du framework
    pause
    exit /b 1
)

REM Nettoyage
if exist %BUILD_DIR% (
    rmdir /s /q %BUILD_DIR%
)
mkdir %BUILD_DIR%\WEB-INF
mkdir %BUILD_DIR%\WEB-INF\classes
mkdir %BUILD_DIR%\WEB-INF\lib

REM Compilation avec les deux JARs (si des fichiers Java existent)
if exist %SRC_DIR%\*.java (
    echo Compilation de l'application Test...
    dir /b /s %SRC_DIR%\*.java > sources.txt
    javac -cp "%SERVLET_API_JAR%;%FRONT_SERVLET_JAR%" -d %BUILD_DIR%\WEB-INF\classes @sources.txt
    if errorlevel 1 (
        echo Erreur de compilation!
        del sources.txt
        pause
        exit /b 1
    )
    del sources.txt
) else (
    echo Aucun fichier Java a compiler dans le projet de test.
    echo Le projet utilise uniquement le framework FrontServlet.
)

REM Copier les librairies
copy /Y %LIB_DIR%\*.jar %BUILD_DIR%\WEB-INF\lib\

REM Copier TOUS les fichiers web
if exist %WEB_DIR% (
    echo Copie des fichiers web...
    xcopy /E /I /Y %WEB_DIR%\* %BUILD_DIR%\
)

REM Création du WAR
echo Creation du WAR %APP_NAME%.war...
cd %BUILD_DIR%
jar -cvf %APP_NAME%.war *
cd ..

set TARGET_WAR=%TEST_DIR%\build\%APP_NAME%.war

REM === Vérification du fichier WAR ===
if not exist "%TARGET_WAR%" (
    echo ❌ ERREUR : Le fichier %WAR_NAME%.war n'a pas été généré !
    echo 📁 Emplacement attendu: %TARGET_WAR%
    pause
    exit /b 1
)
echo ✅ Fichier WAR généré: %TARGET_WAR%

REM === Étape 3: Arrêt de Tomcat (si en cours) ===
echo.
echo 🛑 ÉTAPE 3: Arrêt de Tomcat...
cd /d "%TOMCAT_PATH%\bin\"
if exist "shutdown.bat" (
    call shutdown.bat >nul 2>&1
    echo ⏳ Attente de l'arrêt de Tomcat...
    timeout /t 5 /nobreak >nul
)

REM === Étape 4: Nettoyage du déploiement précédent ===
echo.
echo 🧹 ÉTAPE 4: Nettoyage de l'ancien déploiement...
if exist "%TOMCAT_PATH%\webapps\%WAR_NAME%.war" (
    del /Q "%TOMCAT_PATH%\webapps\%WAR_NAME%.war"
)
if exist "%TOMCAT_PATH%\webapps\%WAR_NAME%" (
    rmdir /S /Q "%TOMCAT_PATH%\webapps\%WAR_NAME%" 2>nul
)

REM === Étape 5: Copie du nouveau WAR ===
echo.
echo 📋 ÉTAPE 5: Copie du nouveau .war dans Tomcat...
copy /Y "%TARGET_WAR%" "%TOMCAT_PATH%\webapps\"
if errorlevel 1 (
    echo ❌ ERREUR : Échec de la copie du fichier WAR
    pause
    exit /b 1
)
echo ✅ Fichier copié: %TOMCAT_PATH%\webapps\%WAR_NAME%.war

REM === Étape 6: Démarrage de Tomcat ===
echo.
echo 🚀 ÉTAPE 6: Démarrage de Tomcat...
cd /d "%TOMCAT_PATH%\bin\"
start "" "startup.bat"

echo ⏳ Attente du démarrage de Tomcat...
timeout /t 10 /nobreak >nul

REM === Étape 7: Vérification du déploiement ===
echo.
echo 🔍 ÉTAPE 7: Vérification du déploiement...
timeout /t 3 /nobreak >nul

echo 📊 Vérification des dossiers déployés...
if exist "%TOMCAT_PATH%\webapps\%WAR_NAME%" (
    echo ✅ Application déployée avec succès!
) else (
    echo ⚠️  Le déploiement peut prendre quelques secondes supplémentaires...
)

REM === Affichage des informations finales ===
echo.
echo ==================================================
echo   ✅ DÉPLOIEMENT TERMINÉ AVEC SUCCÈS !
echo ==================================================
echo.
echo 🌐 URLS DE TEST:
echo.
echo 1. Page d'accueil:        http://localhost:8080/%WAR_NAME%/
echo 2. Route dynamique:       http://localhost:8080/%WAR_NAME%/hello
echo 3. Route dynamique:       http://localhost:8080/%WAR_NAME%/form
echo 4. Fichier statique:      http://localhost:8080/%WAR_NAME%/pages/test.html
echo 5. Fichier statique:      http://localhost:8080/%WAR_NAME%/pages/formulaire.html
echo 6. Test quelconque:       http://localhost:8080/%WAR_NAME%/n-importe-quoi
echo.
echo 📋 RÉSULTAT ATTENDU:
echo - Les routes dynamiques (/hello, /form) affichent le contenu du TestController
echo - Les fichiers statiques (HTML, CSS, JS) sont servis automatiquement
echo - Les URLs inconnues affichent une page d'erreur personnalisée
echo - Le FrontServlet capture et traite toutes les requêtes
echo.
echo 🚀 FONCTIONNALITÉS DISPONIBLES:
echo ✅ Front Controller Pattern
echo ✅ Gestion des fichiers statiques
echo ✅ Système de routes avec @WebRoute
echo ✅ Gestion d'erreurs personnalisée
echo.
echo ⏳ Ouverture automatique du navigateur dans 5 secondes...
timeout /t 5 /nobreak >nul

REM === Ouverture du navigateur ===
start "" "http://localhost:8080/%WAR_NAME%/"

echo.
echo 💡 Pour arrêter Tomcat: exécutez shutdown.bat dans %TOMCAT_PATH%\bin\
echo 💡 Pour redéployer: relancez ce script
echo.
pause
