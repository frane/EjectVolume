EjectVolumeWidget = {    
    setup: function(){
        doneButton = new CreateGlassButton(document.getElementById("done_button"), {text: "Done", onclick: EjectVolumeWidget.hidePrefs});
        infoButton = new CreateInfoButton(document.getElementById("info_button"), {frontID: "front", backgroundStyle: "black", foregroundStyle: "white", onclick: EjectVolumeWidget.showPrefs});
        EjectVolumeWidget.remove(); // clean up the cache
    },

    showPrefs: function(e){
        window.resizeTo(window.innerWidth, 160);

        var front = document.getElementById("front");
        var back = document.getElementById("back");

        if (window.widget)
            widget.prepareForTransition("ToBack");

	 
        front.style.display="none";
        back.style.display="block";

        if (window.widget)
            setTimeout ('widget.performTransition();', 0);
    },

    hidePrefs: function(e){    
        var front = document.getElementById("front");
        var back = document.getElementById("back");
        
        if (window.widget)
            widget.prepareForTransition("ToFront");
        
        back.style.display="none";
        front.style.display="block";
        
        EjectVolumeWidget.updateVolumes();

        if (window.widget)
            setTimeout ('widget.performTransition();', 0);
    },

    remove: function() {
        if(EjectVolume)
            EjectVolume.clearCacheDir();
    },
    
    sync: function() {
        EjectVolumeWidget.remove();
        EjectVolumeWidget.updateVolumes();
    },
    
    hide: function() {},
    
    show: function() {
        EjectVolumeWidget.updateVolumes();
    }, 

    addElement: function(element){
        volumeElement = document.createElement('li');
        
        volumeText = null;
        if(element[0].length > 19) {
            volumeText = document.createElement('attr');
            volumeText.innerHTML = element[0].substring(0, 17) + '...'; 
        } else {
            volumeText = document.createElement('span');
            volumeText.innerHTML = element[0]; 
        }
        volumeText.className += 'volume_text';
        
        volumeIcon = document.createElement('img');
        volumeIcon.src = element[2];
        volumeIcon.className += 'volume_icon';
        
        volumeEject = document.createElement('div');
        volumeEject.className += 'volume_eject';
        volumeEject.onclick = function(e){ EjectVolumeWidget.unmount(element[1])}; 
        
        volumeElement.appendChild(volumeIcon);
        volumeElement.appendChild(volumeText);
        volumeElement.appendChild(volumeEject);
        document.getElementById('volumes').appendChild(volumeElement);
        EjectVolumeWidget.mountpoints.push(element[1]);
        window.resizeTo(window.innerWidth, window.innerHeight+30);
    },
    
    addEjectAllElement: function(){
        volumeElement = document.createElement('div');
        volumeElement.id = "eject_all";
        
        volumeText = document.createElement('span');
        volumeText.innerHTML = "Eject All";
        volumeText.id = 'eject_all_text';
        
        ejectAll = document.createElement('div');
        ejectAll.id = 'eject_all_button';
        ejectAll.onclick = function(e){ 
            for(i = 0; i < EjectVolumeWidget.mountpoints.length; i++)
                EjectVolume.unmountVolume(EjectVolumeWidget.mountpoints[i]);
            
            EjectVolumeWidget.updateVolumes();
        }; 
        
        volumeElement.appendChild(ejectAll);
        volumeElement.appendChild(volumeText);
        document.getElementById('title').appendChild(volumeElement);
        window.resizeTo(window.innerWidth, window.innerHeight+30);
    },
    
    mountpoints: [],
    
    updateVolumes: function(){
        document.getElementById('volumes').innerHTML = "";
        EjectVolumeWidget.mountpoints = [];
        
        if(EjectVolume) {
            volumeList = EjectVolume.getVolumes();
            if(volumeList.length > 1) {
                if(!document.getElementById('eject_all'))
                    EjectVolumeWidget.addEjectAllElement();
            } else {
                if(document.getElementById('eject_all') && typeof document.getElementById('eject_all') != 'undefined')
                    document.getElementById('title').removeChild(document.getElementById('eject_all'));
            }
            for(var i = 0; i < volumeList.length; i++) {
                EjectVolumeWidget.addElement(volumeList[i]);
            }
        } else { // Fallback to pre 0.3 method
            out = widget.system("/bin/df -l", null).outputString.split("\n");
            outArr = null;
            for(var i = 0; i < out.length; i++){
                outArr = out[i].split("%");
                if(outArr[1] && outArr[1].indexOf("/Volumes/") == 4) {
                    EjectVolumeWidget.addElement([outArr[1].replace("/Volumes/", ""), outArr[1], ""]);
                }
            }
        }
    },

    unmount: function(mountpoint){
        if (EjectVolume) {
            EjectVolume.unmountVolume(mountpoint);
        } else {
            widget.system("/usr/sbin/diskutil eject '" + mountpoint.slice(mountpoint.indexOf("/"), mountpoint.length) + "'", function(e){ EjectVolumeWidget.updateVolumes });
        }
        EjectVolumeWidget.updateVolumes();
    }
};

if (window.widget) {
    widget.onremove = EjectVolumeWidget.remove;
    widget.onhide = EjectVolumeWidget.hide;
    widget.onshow = EjectVolumeWidget.show;
    widget.onsync = EjectVolumeWidget.sync;
}