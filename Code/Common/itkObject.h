/*=========================================================================

  Program:   Insight Segmentation & Registration Toolkit
  Module:    itkObject.h
  Language:  C++
  Date:      $Date$
  Version:   $Revision$


  Copyright (c) 2000 National Library of Medicine
  All rights reserved.

  See COPYRIGHT.txt for copyright details.

=========================================================================*/
/**
 * itkObject is the second-highest level base class for most itk objects.
 * It extends the base object functionality of itkLightObject by
 * implementing debug flags/methods and modification time tracking.
 */

#ifndef __itkObject_h
#define __itkObject_h

#include <iostream>
#include <typeinfo>

#include "itkLightObject.h"
#include "itkSmartPointer.h"
#include "itkTimeStamp.h"
#include "itkIndent.h"
#include "itkSetGet.h"

class ITK_EXPORT itkObject: public itkLightObject
{
public:
  /** 
   * Smart pointer typedef support.
   */
  typedef itkObject              Self;
  typedef itkSmartPointer<Self>  Pointer;

  /** 
   * Create an object with Debug turned off, modified time initialized to
   * zero, and reference count set to 1. 
   */
  static Pointer New();

  /** 
   * Standard part of all itk objects.
   */
  itkTypeMacro(itkObject, itkLightObject);

  /** 
   * Turn debugging output on. 
   */
  virtual void DebugOn();

  /** 
   * Turn debugging output off. 
   */
  virtual void DebugOff();
  
  /** 
   * Get the value of the debug flag. 
   */
  bool GetDebug() const;
  
  /** 
   * Set the value of the debug flag. A non-zero value turns debugging on.
   */
  void SetDebug(bool debugFlag);
  
  /** 
   * Return this objects modified time. 
   */
  virtual unsigned long GetMTime();

  /** 
   * Update the modification time for this object. Many filters rely on the
   * modification time to determine if they need to recompute their data. 
   */
  virtual void Modified();
  
  /** 
   * Increase the reference count (mark as used by another object). 
   */
  virtual void Register();

  /** 
   * Decrease the reference count (release by another object). 
   */
  virtual void UnRegister();

  /** 
   * Gets the reference count (use with care) 
   */
  virtual int GetReferenceCount() const {return m_ReferenceCount;}

  /** 
   * Sets the reference count (use with care) 
   */
  virtual void SetReferenceCount(int);

  /** 
   * A callback for when the destructor is called. Scripting
   * languages use this to know when a C++ object has been freed.
   * This is not intended for any use other than scripting. 
   */
  virtual void SetDeleteMethod(void (*f)(void *));
  
  /** 
   * This is a global flag that controls whether any debug, warning
   *  or error messages are displayed. 
   */
  static void SetGlobalWarningDisplay(bool flag);
  static bool GetGlobalWarningDisplay();

  static void GlobalWarningDisplayOn()
    { itkObject::SetGlobalWarningDisplay(true); }
  static void GlobalWarningDisplayOff()
    { itkObject::SetGlobalWarningDisplay(false); }
  
protected:
  itkObject(); 
  virtual ~itkObject(); 
  itkObject(const Self&) {}
  void operator=(const Self&) {}

  /** 
   * Methods invoked by Print() to print information about the object
   * including superclasses. Typically not called by the user (use Print()
   * instead) but used in the hierarchical print process to combine the
   * output of several classes. 
   */
  virtual void PrintSelf(std::ostream& os, itkIndent indent);
  virtual void PrintHeader(std::ostream& os, itkIndent indent);
  virtual void PrintTrailer(std::ostream& os, itkIndent indent);

private:
  /**
   * Enable/Disable debug messages.
   */
  bool m_Debug;
  
  /**
   * Keep track of modification time.
   */
  itkTimeStamp m_MTime;
  
  /**
   * Global object debug flag.
   */
  static bool m_GlobalWarningDisplay;
};

#endif

