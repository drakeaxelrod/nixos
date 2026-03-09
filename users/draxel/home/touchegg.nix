# Touchegg gesture config - matches KDE Plasma 6 defaults
# Daemon must be enabled at system level: services.touchegg.enable = true
{ ... }:

{
  xdg.configFile."touchegg/touchegg.conf".text = ''
    <touchégg>
      <settings>
        <property name="animation_delay">150</property>
        <property name="action_execute_threshold">20</property>
        <property name="color">auto</property>
        <property name="borderColor">auto</property>
      </settings>
      <application name="All">
        <!-- 3-finger swipe up: Overview -->
        <gesture type="SWIPE" fingers="3" direction="UP">
          <action type="RUN_COMMAND">
            <repeat>false</repeat>
            <command>qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Overview"</command>
            <on>begin</on>
          </action>
        </gesture>
        <!-- 3-finger swipe down: Show Desktop -->
        <gesture type="SWIPE" fingers="3" direction="DOWN">
          <action type="RUN_COMMAND">
            <repeat>false</repeat>
            <command>qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Show Desktop"</command>
            <on>begin</on>
          </action>
        </gesture>
        <!-- 3-finger swipe left: Next Desktop -->
        <gesture type="SWIPE" fingers="3" direction="LEFT">
          <action type="RUN_COMMAND">
            <repeat>false</repeat>
            <command>qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Switch to Next Desktop"</command>
            <on>begin</on>
          </action>
        </gesture>
        <!-- 3-finger swipe right: Previous Desktop -->
        <gesture type="SWIPE" fingers="3" direction="RIGHT">
          <action type="RUN_COMMAND">
            <repeat>false</repeat>
            <command>qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Switch to Previous Desktop"</command>
            <on>begin</on>
          </action>
        </gesture>
        <!-- 4-finger swipe up: Show Desktop -->
        <gesture type="SWIPE" fingers="4" direction="UP">
          <action type="RUN_COMMAND">
            <repeat>false</repeat>
            <command>qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Show Desktop"</command>
            <on>begin</on>
          </action>
        </gesture>
        <!-- 4-finger swipe down: Overview -->
        <gesture type="SWIPE" fingers="4" direction="DOWN">
          <action type="RUN_COMMAND">
            <repeat>false</repeat>
            <command>qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Overview"</command>
            <on>begin</on>
          </action>
        </gesture>
      </application>
    </touchégg>
  '';
}
