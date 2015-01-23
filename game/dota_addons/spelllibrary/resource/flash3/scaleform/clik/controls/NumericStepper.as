﻿/**
 *  The NumericStepper component displays a single number in the range assigned to it, and supports the ability to increment and decrement the value based on an arbitrary step size.
    
    <b>Inspectable Properties</b>
    A NumericStepper component will have the following inspectable properties:<ul>
    <li><i>enabled</i>: Disables the component if set to false.</li>
    <li><i>focusable</i>: By default, NumericStepper can receive focus for user interactions. Setting this property to false will disable focus acquisition.</li>
    <li><i>minimum</i>: The minimum value of the NumericStepper’s range.</li> 
    <li><i>maximum</i>: The maximum value of the NumericStepper’s range.</li>
    <li><i>value</i>: The numeric value displayed by the NumericStepper.</li>
    <li><i>visible</i>: Hides the component if set to false.</li>
    
    <b>States</b>
    The NumericStepper component supports three states based on its focused and disabled properties. <ul>
    <li>default or enabled state.</li>
    <li>focused state, that highlights the textField area.</li>
    <li>disabled state.</li></ul>
    
    <b>Events</b>
    All event callbacks receive a single Event parameter that contains relevant information about the event. The following properties are common to all events. <ul>
    <li><i>type</i>: The event type.</li>
    <li><i>target</i>: The target that generated the event.</li></ul>
        
    The events generated by the NumericStepper component are listed below. The properties listed next to the event are provided in addition to the common properties.
    <ul>
        <li><i>ComponentEvent.SHOW</i>: The visible property has been set to true at runtime.</li>
        <li><i>ComponentEvent.HIDE</i>: The visible property has been set to false at runtime.</li>
        <li><i>ComponentEvent.STATE_CHANGE</i>: The NumericStepper's state has changed.</li>
        <li><i>FocusHandlerEvent.FOCUS_IN</i>: The NumericStepper has received focus.</li>
        <li><i>FocusHandlerEvent.FOCUS_OUT</i>: The NumericStepper has lost focus.</li>
        <li><i>IndexEvent.INDEX_CHANGE</i>: The NumericStepper's value has changed.</li>
        <li><i>ButtonEvent.CLICK</i>: The next or previous Button of the NumericStepper has been clicked.</li>
    </ul>
 */
    
/**************************************************************************

Filename    :   NumericStepper.as

Copyright   :   Copyright 2012 Autodesk, Inc. All Rights reserved.

Use of this software is subject to the terms of the Autodesk license
agreement provided at the time of installation or download, or which
otherwise accompanies this software in either electronic or hard copy form.

**************************************************************************/
    
package scaleform.clik.controls {
    
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    
    import scaleform.clik.constants.ConstrainMode;
    import scaleform.clik.constants.InvalidationType;
    import scaleform.clik.core.UIComponent;
    import scaleform.clik.events.InputEvent;
    import scaleform.clik.events.ButtonEvent;
    import scaleform.clik.events.IndexEvent;
    import scaleform.clik.events.ComponentEvent;
    import scaleform.clik.constants.ControllerType;
    import scaleform.clik.ui.InputDetails;
    import scaleform.clik.constants.InputValue;
    import scaleform.clik.constants.NavigationCode;
    import scaleform.clik.utils.Constraints;
    import scaleform.clik.utils.ConstrainedElement;
    
    public class NumericStepper extends UIComponent {
        
    // Constants:
        
    // Public Properties:
        /** The amount the value is incremented or decremented. */
        [Inspectable(defaultValue="1")]
        public var stepSize:Number = 1;
        /** True if constraints are disabled for the component. Setting the disableConstraintsproperty to {@code disableConstraints=true} will remove constraints from the textfield. This is useful for components with timeline based textfield size tweens, since constraints break them due to a Flash quirk. */
        public var constraintsDisabled:Boolean = false;
        
    // Protected Properties:
        protected var _maximum:Number = 10;
        protected var _minimum:Number = 0;
        protected var _stepSize:Number;
        protected var _value:Number = 0;
        protected var _labelFunction:Function;
        protected var state:String = "default";
        protected var _newFrame:String;
        
    // UI Elements:
        /** A reference to the textField instance used to display the selected item's label. Note that when state changes are made, the textField instance may change, so changes made to it externally may be lost. */
        public var textField:TextField;
        /** A reference to the next button instance used to increment the {@code selectedIndex}. */
        public var nextBtn:Button;
        /** A reference to the previous button instance used to decrement the {@code selectedIndex}. */
        public var prevBtn:Button;
        
        public var container:MovieClip;
        
    // Initialization:
        public function NumericStepper() {
            super();
        }
        
        override protected function preInitialize():void {
            if (!constraintsDisabled) {
                constraints = new Constraints(this, ConstrainMode.COUNTER_SCALE);
            }
        }
        
        override protected function initialize():void {
            super.initialize();
        }
        
    // Public getter / setters:
        [Inspectable(defaultValue="true")]
        override public function get enabled():Boolean { return super.enabled; }
        override public function set enabled(value:Boolean):void {
            if (value == super.enabled) { return; }
            super.enabled = value;
            
            mouseEnabled = tabEnabled = value;
            gotoAndPlay( value ? ((_focused > 0) ? "focused" : "default") : "disabled" );
            if (!initialized) { return; }
            
            updateAfterStateChange();
            prevBtn.enabled = nextBtn.enabled = value;
        }
        
        /**
         * Enable/disable focus management for the component. Setting the focusable property to 
         * {@code focusable=false} will remove support for tab key, direction key and mouse
         * button based focus changes.
         */
        [Inspectable(defaultValue="true")]
        override public function get focusable():Boolean { return _focusable; }
        override public function set focusable(value:Boolean):void { 
            super.focusable = value;
        }
        
        /**
         * The maximum allowed value. The {@code value} property will always be less than or equal to the {@code maximum}. 
         */
        [Inspectable(defaultValue="10")]
        public function get maximum():Number { return _maximum; }
        public function set maximum(value:Number):void {
            _maximum = value;
            value = _value;
        }    
        
        /**
         * The minimum allowed value. The {@code value} property will always be greater than or equal to the {@code minimum}. 
         */
        [Inspectable(defaultValue="0")]
        public function get minimum():Number { return _minimum; }
        public function set minimum(value:Number):void {
            _minimum = value;
            value = _value;
        }
        
        /**
         * The value of the numeric stepper. The {@code value} property will always be kept between the {@code mimimum} and {@code maximum}.
         * @see #minimum
         * @see #maximum
         */
        [Inspectable(name="value", defaultValue="0")]
        public function get value():Number { return _value; }
        public function set value(v:Number):void {
            v = lockValue(v);
            if (v == _value) { return; }
            var previousValue:Number = _value;
            _value = v;
            if (initialized) {
                dispatchEventAndSound(new IndexEvent(IndexEvent.INDEX_CHANGE, true, false, value, previousValue, null));
            }
            invalidate();
        }
        
        /**
         * The function used to determine the label.
         */
        public function get labelFunction():Function { return _labelFunction; }
        public function set labelFunction(value:Function):void {
            _labelFunction = value;
            updateLabel();
        }

    // Public Methods:
        /** Increment the {@code value} of the NumericStepper, using the {@code stepSize}. */
        public function increment():void { onNext(null); }
        
        /** Decrement the {@code value} of the NumericStepper, using the {@code stepSize}. */
        public function decrement():void { onPrev(null); }
        
        override public function handleInput(event:InputEvent):void {
            if (event.isDefaultPrevented()) { return; }
            var details:InputDetails = event.details;
            var index:uint = details.controllerIndex;
            
            var keyPress:Boolean = (details.value == InputValue.KEY_DOWN || details.value == InputValue.KEY_HOLD);
            switch (details.navEquivalent) {
                case NavigationCode.RIGHT:
                    if (_value < _maximum) {
                        if (keyPress) { onNext(null); }
                        event.handled = true;
                    }
                    break;
                case NavigationCode.LEFT:
                    if (_value > _minimum) {
                        if (keyPress) { onPrev(null); }
                        event.handled = true;
                    }
                    break;
                case NavigationCode.HOME:
                    if (!keyPress) { value = _minimum }
                    event.handled = true;
                    break;
                case NavigationCode.END:
                    if (!keyPress) { value = _maximum; }
                    event.handled = true;
                    break;
            }
        }
        
        override public function toString():String { 
            return "[CLIK NumericStepper " + name + "]";
        }
        
    // Protected Methods:
        override protected function configUI():void {
            if (!constraintsDisabled) {  
                constraints.addElement("textField", textField, Constraints.LEFT | Constraints.RIGHT);
            }
            
            addEventListener(InputEvent.INPUT, handleInput, false, 0, true);
            nextBtn.addEventListener(ButtonEvent.CLICK, onNext, false, 0, true);
            prevBtn.addEventListener(ButtonEvent.CLICK, onPrev, false, 0, true);
            
            tabEnabled = _focusable;
            tabChildren = false;
            
            // Prevent internal components from preventing mouse focus moves to the component.
            if (textField != null) {
				textField.tabEnabled = textField.mouseEnabled = false;
			}
			if (container != null) { 
				container.tabEnabled = container.mouseEnabled = false;
			}
            
            prevBtn.enabled = nextBtn.enabled = enabled;
            prevBtn.autoRepeat = nextBtn.autoRepeat = true;
            prevBtn.focusable = nextBtn.focusable = false;
            prevBtn.focusTarget = nextBtn.focusTarget = this;
            prevBtn.tabEnabled = nextBtn.tabEnabled = false;
            prevBtn.mouseEnabled = nextBtn.mouseEnabled = true;
        }
        
        override protected function draw():void {
            // State is invalid, and has been set (is not the default)
            if (isInvalid(InvalidationType.STATE)) {
                if (_newFrame) {
                    gotoAndPlay(_newFrame);
                    _newFrame = null;
                }
                
                updateAfterStateChange();
                dispatchEventAndSound(new ComponentEvent(ComponentEvent.STATE_CHANGE));
            }
            
            if (isInvalid(InvalidationType.DATA)) {
                updateLabel();
            }
            
            // Resize and update constraints
            if (isInvalid(InvalidationType.SIZE)) {
                setActualSize(_width, _height);
                if (!constraintsDisabled) {
                    constraints.update(_width, _height);
                }
            }
        }
        
        override protected function changeFocus():void {
            if (_focused || _displayFocus) {
                setState("focused", "default");
            } else {
                setState("default");
            }
            
            updateAfterStateChange();
            prevBtn.displayFocus = nextBtn.displayFocus = (_focused > 0);
        }

        protected function handleDataChange(event:Event):void {
            invalidate(InvalidationType.DATA);
        }

        protected function updateAfterStateChange():void {
            invalidateSize();
            updateLabel();
            
            // Update the children's mouseEnabled/tabEnabled settings in case new instances have been created.
            if (textField != null) {
				textField.tabEnabled = textField.mouseEnabled = false;
			}
			if (container != null) { 
				container.tabEnabled = container.mouseEnabled = false;
			}
			
            if (constraints != null && !constraintsDisabled) {
                constraints.updateElement("textField", textField); // Update references in Constraints 
            }
        }
        
        protected function updateLabel():void {
            var label:String = _value.toString();
            if (_labelFunction != null) { 
                label = _labelFunction(_value);
            }
            textField.text = label;
        }
        
        protected function onNext( event:ButtonEvent ):void {
            value = _value + stepSize;
        }
        
        protected function onPrev( event:ButtonEvent ):void {
            value = _value - stepSize;
        }
        
        protected function setState(...states:Array):void {
            if (states.length == 1) {
                var onlyState:String = states[0].toString();
                if (state != onlyState && _labelHash[onlyState]) { 
                    state = _newFrame = onlyState;
                    invalidateState();
                }
                return;
            }
            var l:uint = states.length;
            for (var i:uint=0; i<l; i++) {
                var thisState:String = states[i].toString();
                if (_labelHash[thisState]) {
                    state = _newFrame = thisState;
                    invalidateState();
                    break;
                }
            }
        }
        
        // Lock the value to the step size and min/max
        protected function lockValue(value:Number):Number {
            var newVal:Number = Math.max(_minimum, Math.min(_maximum, stepSize * Math.round(value / stepSize)));
            return newVal;
        }
    }
}