//  Source File Name: PluginEx.java  1.2
//
//  Licensed Materials -- Property of IBM
//
//  (c) Copyright International Business Machines Corporation, 1999.
//      All Rights Reserved.
//
//  US Government Users Restricted Rights -
//  Use, duplication or disclosure restricted by
//  GSA ADP Schedule Contract with IBM Corp.
//
//  Sample Program PluginEx - Client program to add new menu items and toolbar
//                            buttons to the Control Center
//
//  Steps to run the sample:
//  (1) you must have the "DB2" instance cataloged on the client
//  (2) you must have the "sample" database cataloged on the client
//  (3) replace "XXXXX" string in this file with your system name.
//  (4) compile this java file (javac PluginEx.java).
//      On Windows 32-bit and the OS/2 operating systems,
//      your CLASSPATH must include the DRIVE:\sqllib\java\swingall.jar
//      file, the DRIVE:\sqllib\cc\db2cc.jar file, and the
//      DRIVE:\sqllib\cc directory to compile this sample
//      (where DRIVE: represents the drive on which DB2 is installed).
//      On UNIX platforms, CLASSPATH must include
//      /u/db2inst1/sqllib/cc, /u/db2inst1/sqllib/cc/db2cc.jar, and
//      /u/db2inst1/sqllib/java/swingall.jar, where /u/db2inst1
//      represents the directory on which DB2 is installed.
//  (5) create db2plug.zip (zip -0 db2plug.zip PluginEx.class)
//  (6) put db2plug.zip in where the Control Center is run.
//  (7) Run the Control Center.
//
//  NOTES: (1) The jdk11_path database manager configuration parameter must
//             be set
//         (2) The CLASSPATH and shared library path environment variables
//             must be set.
//         (3) Visit http://www.software.ibm.com/data/db2/java
//             for current DB2 Java information

// For more information about this sample, refer to the README file.

// For more information about the Control Center
// For more information on programming in Java, refer to the
// "Programming in Java" section of the Application Development Guide.

// For more information on building and running Java programs for DB2,
// refer to the "Building Java Applets and Applications" section of the
// Application Building Guide.

// For more information on the SQL language, refer to the SQL Reference.

import com.ibm.db2.tools.cc.navigator.*;
import java.awt.event.*;
import javax.swing.*;

/**
 * This CCExtension interface allows user to extend the Control Center user
 * interface by adding new toolbar buttons, new menu items and
 * remove some predefined set of existing menu actions.
 * <p>
 * To do so, create a java file which imports the com.ibm.db2.tools.cc.navigator package and
 * implements this interface.  The new file provides the implementation
 * of the getObjects() and getToolbarActions() function.
 * <p>
 * The getObjects() function returns an array of CCObjects which defines
 * the existing
 * objects which the user would like to add new menu actions or remove
 * the alter or configure menu actions.
 * <p>
 * The getToolbarActions() function returns an array of CCToolbarActions which is
 * added to the Control Center main toolbar.
 * <p>
 * This CCExtension subclass file will define a sample Control Center extensions.
 * In order for the Control Center to make use of these extensions, use the following
 * setup procedures:
 * (1) Create a "db2plug.zip" file which contains all this CCExtension subclass file.
 *     The file should not be compressed. For example, issues
 *        zip -r0 db2plug.zip PluginEx.class
 *     This command will put all the class files into the db2plug.zip
 *     file and preserve the relative path information.
 * (2) To run WEBCC as an applet, put the db2plug.zip file in where the <codebase>
 *     tag points to in the WEBCC html file. To run WEBCC as an application, put
 *     the db2plug.zip in a directory pointed to by the CLASSPATH envirnoment variable.
 * <p>
 * For browsers that support multiple archives, just add "db2plug.zip" to the archive list
 * of the WEBCC html page. Otherwise, all the CCExtension, CCObject, CCToolbarAction, CCMenuAction subclass
 * files will have to be in their relative path depending on which package they belong to.
 * In this case, this extension does not belong to any package.
 */
public class PluginEx implements CCExtension
{
   /**
    * Return an array of CCObject subclass objects which define
    * a list of Control Center objects to override
    */
   public CCObject[] getObjects()
   {
      CCObject[] objs = new CCObject[14];
      objs[0] = new MySample();
      objs[1] = new MyDatabaseActions();
      objs[2] = new MyDB2();
      objs[3] = new MyDatabasesFolder();
      objs[4] = new MySYSPLAN();
      objs[5] = new MyDBUsersFolder();
      objs[6] = new MyPackagesFolder();
      objs[7] = new MySQLE28N6();
      objs[8] = new MyUserGroupObjectsFolder();
      objs[9] = new MyDataTypeActions();
      objs[10]= new MyInstancesFolder();
      objs[11]= new MySystemsFolder();
      objs[12]= new MyXXXXX();
      objs[13]= new MyIndexActions();
      return objs;
   }

   public CCToolbarAction[] getToolbarActions()
   {
      CCToolbarAction[] actions = new CCToolbarAction[1];
      actions[0] = new MyToolbarAction();
      return actions;
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX - DB2 - SAMPLE packages foler.
    */
   class MyPackagesFolder implements CCObject
   {
      public String getName()
      {
         return "XXXXX - DB2 - SAMPLE";
      }

      public int getType()
      {
         return UDB_PACKAGES_FOLDER;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[1];
         acts[0] = new MyCreateAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX-DB2-SAMPLE database
    * and remove the Alter/Change and Configure menu items.
    */
   class MySample implements CCObject
   {
      public String getName()
      {
         return "XXXXX - DB2 - SAMPLE";
      }

      public int getType()
      {
         return UDB_DATABASE;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[2];
         acts[0] = new MyAlterAction();
         acts[1] = new MyAction();
         return acts;
      }

      public boolean isEditable() { return false; }
      public boolean isConfigurable() { return false; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX-DB2-SAMPLE-NULLID.SQLE28N6 package.
    */
   class MySQLE28N6 implements CCObject
   {
      public String getName()
      {
         return "XXXXX - DB2 - SAMPLE-NULLID.SQLE28N6";
      }

      public int getType()
      {
         return UDB_PACKAGE;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[1];
         acts[0] = new MyAlterAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX-DB2-SAMPLE-SYSIBM.SYSPLAN table
    * and remove the Alter/Change menu items.
    */
   class MySYSPLAN implements CCObject
   {
      public String getName()
      {
         return "XXXXX - DB2 - SAMPLE - SYSIBM.SYSPLAN";
      }

      public int getType()
      {
         return UDB_TABLE;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[2];
         acts[0] = new MyAlterAction();
         acts[1] = new MyAction();
         return acts;
      }

      public boolean isEditable() { return false; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the button to be added to
    * the Control Center toolbar.
    */
   class MyToolbarAction implements CCToolbarAction
   {
      public String getHoverHelpText()
      {
         return "MyToolbarAction";
      }

      public ImageIcon getIcon()
      {
         //Return your ImageIcon here
         return null;
      }

      public void actionPerformed(ActionEvent e)
      {
         System.out.println( "My toolbar action performed, object name = " + e.getActionCommand() );
      }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX-DB2-SAMPLE user and group objects folder.
    */
   class MyUserGroupObjectsFolder implements CCObject
   {
      public String getName()
      {
         return "XXXXX - DB2 - SAMPLE";
      }

      public int getType()
      {
         return UDB_USER_AND_GROUP_OBJECTS_FOLDER;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[2];
         acts[0] = new MyAlterAction();
         acts[1] = new MyAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX instances folder.
    */
   class MyInstancesFolder implements CCObject
   {
      public String getName()
      {
         return "XXXXX";
      }

      public int getType()
      {
         return UDB_INSTANCES_FOLDER;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[1];
         acts[0] = new MyCreateAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the systems folder.
    */
   class MySystemsFolder implements CCObject
   {
      public String getName()
      {
         return null;
      }

      public int getType()
      {
         return UDB_SYSTEMS_FOLDER;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[1];
         acts[0] = new MyCreateAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX system.
    */
   class MyXXXXX implements CCObject
   {
      public String getName()
      {
         return "XXXXX";
      }

      public int getType()
      {
         return UDB_SYSTEM;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[2];
         acts[0] = new MyAlterAction();
         acts[1] = new MyAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of all the UDB index objects
    * and remove the Alter/Change menu item.
    */
   class MyIndexActions implements CCObject
   {
      public String getName()
      {
         return null;
      }

      public int getType()
      {
         return UDB_INDEX;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[1];
         acts[0] = new MyCreateAction();
         return acts;
      }

      public boolean isEditable() { return false; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the MyAction menu items.
    */
   class MyAction implements CCMenuAction
   {
      public String getMenuText()
      {
         return "MyAction";
      }

      public void actionPerformed(ActionEvent e)
      {
         System.out.println( "My action performed, object name = " + e.getActionCommand() );
      }
   }

   /**
    * The class defines the MyAlterAction menu items.
    */
   class MyAlterAction implements CCMenuAction
   {
      public String getMenuText()
      {
         return "My Alter";
      }

      public void actionPerformed(ActionEvent e)
      {
         System.out.println( "My alter action performed, object name = " + e.getActionCommand() );
      }
   }

   /**
    * The class defines the MyCreateAction menu items.
    */
   class MyCreateAction implements CCMenuAction
   {
      public String getMenuText()
      {
         return "My create";
      }

      public void actionPerformed(ActionEvent e)
      {
         System.out.println( "My create action performed, object name = " + e.getActionCommand() );
      }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of all the UDB database objects.
    */
   class MyDatabaseActions implements CCObject
   {
      public String getName()
      {
         return null;
      }

      public int getType()
      {
         return UDB_DATABASE;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[2];
         acts[0] = new MyDropAction();
         acts[1] = new MyAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the MyDropAction menu items.
    */
   class MyDropAction implements CCMenuAction
   {
      public String getMenuText()
      {
         return "MyDrop";
      }

      public void actionPerformed(ActionEvent e)
      {
         System.out.println( "My drop action performed, object name = " + e.getActionCommand() );
      }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX-DB2 UDB databases folder.
    */
   class MyDatabasesFolder implements CCObject
   {
      public String getName()
      {
         return "XXXXX - DB2";
      }

      public int getType()
      {
         return UDB_DATABASES_FOLDER;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[1];
         acts[0] = new MyCreateAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of all the UDB data type objects.
    */
   class MyDataTypeActions implements CCObject
   {
      public String getName()
      {
         return null;
      }

      public int getType()
      {
         return UDB_USER_DEFINED_DISTINCT_DATATYPE;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[2];
         acts[0] = new MyDropAction();
         acts[1] = new MyAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX-DB2 instance and
    * and remove the Alter/Change and Configure menu items.
    */
   class MyDB2 implements CCObject
   {
      public String getName()
      {
         return "XXXXX - DB2";
      }

      public int getType()
      {
         return UDB_INSTANCE;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[2];
         acts[0] = new MyAlterAction();
         acts[1] = new MyAction();
         return acts;
      }

      public boolean isEditable() { return false; }
      public boolean isConfigurable() { return false; }
   }

   /**
    * The class defines the menu items to be added to
    * popup menu of the XXXXX-DB2-SAMPLE DB Users folder.
    */
   class MyDBUsersFolder implements CCObject
   {
      public String getName()
      {
         return "XXXXX - DB2 - SAMPLE";
      }

      public int getType()
      {
         return UDB_DB_USERS_FOLDER;
      }

      public CCMenuAction[] getMenuActions()
      {
         CCMenuAction[] acts = new CCMenuAction[2];
         acts[0] = new MyAlterAction();
         acts[1] = new MyAction();
         return acts;
      }

      public boolean isEditable() { return true; }
      public boolean isConfigurable() { return true; }
   }

}
