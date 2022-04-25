<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:hex="http://drahos.me/hex"
xmlns:xlink="http://www.w3.org/1999/xlink"
xmlns="http://www.w3.org/2000/svg"
version="2.0"    >

    <xsl:output method="xml" indent="yes"/>

    <xsl:variable name="colormap">
        <hex:entry key="0">white</hex:entry>
        <hex:entry key="1">yellow</hex:entry>
        <hex:entry key="2">blue</hex:entry>
        <hex:entry key="3">red</hex:entry>
        <hex:entry key="4">purple</hex:entry>
        <hex:entry key="5">orange</hex:entry>
        <hex:entry key="6">green</hex:entry>
        <hex:entry key="7">brown</hex:entry>
        <hex:entry key="8">black</hex:entry>
        <hex:entry key="9">yellow</hex:entry>
        <hex:entry key="10">blue</hex:entry>
        <hex:entry key="11">red</hex:entry>
        <hex:entry key="12">purple</hex:entry>
        <hex:entry key="13">orange</hex:entry>
        <hex:entry key="14">green</hex:entry>
        <hex:entry key="15">brown</hex:entry>
    </xsl:variable>

    <xsl:template match="/hex:hex">
        <svg width="2000" height="2000" viewbox="0 0 2000 2000">
            <mask id="inner" color="black">
                <circle cx="0" cy="0" r="25" fill="white" 
                stroke-width="1" stroke="black"/>
            </mask>
            <defs>
                <g id="solid" stroke="black" stroke-width="1">
                    <circle cx="0" cy="0" r="25"/>
                </g>
                <g id="stripe" stroke="black" stroke-width="1">
                    <circle cx="0" cy="0" r="25" fill="white"/>
                    <rect x="-14" y="-25" width="28" height="50" 
                    mask="url(#inner)" stroke-width="0"/>
                </g>
            </defs>

            <xsl:for-each select="hex:digit">
                <xsl:choose>
                    <xsl:when test="@d > 8">
                        <use x="{((position() - 1) mod 10) * 75 + 50}" 
                        y="{floor((position() - 1) div 10) * 75 + 50} " 
                        xlink:href="#stripe" 
                        fill="{$colormap/hex:entry[@key=current()/@d]}" />
                    </xsl:when>
                    <xsl:otherwise>
                        <use x="{((position() - 1) mod 10) * 75 + 50}" 
                        y="{floor((position() - 1) div 10) * 75 + 50} " 
                        xlink:href="#solid" 
                        fill="{$colormap/hex:entry[@key=current()/@d]}" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </svg>
    </xsl:template>

</xsl:stylesheet>
