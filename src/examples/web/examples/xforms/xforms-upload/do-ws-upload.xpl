<!--
    Copyright (C) 2004 Orbeon, Inc.

    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.

    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline"
          xmlns:delegation="http://orbeon.org/oxf/xml/delegation"
          xmlns:oxf="http://www.orbeon.com/oxf/processors">

    <p:param name="instance" type="input"/>
    <p:param name="data" type="output"/>

    <!-- Upload all the files -->
    <p:for-each href="#instance" select="/*/files/file" ref="data" root="urls">

        <p:choose href="current()">
            <p:when test="/file != '' and /file/@size &lt;= 160000">
                <!-- File size is reasonable -->

                <!-- Dereference the xs:anyURI obtained from the instance -->
                <p:processor name="oxf:pipeline">
                    <p:input name="config" href="read-uri.xpl"/>
                    <p:input name="uri" href="aggregate('uri', current()#xpointer(string(/file)))"/>
                    <p:output name="data" id="file"/>
                </p:processor>

                <!-- Create the configuration of the Delegation processor -->
                <p:processor name="oxf:xslt">
                    <p:input name="data" href="aggregate('root', #file, current())"/>
                    <p:input name="config">
                        <xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
                            <xsl:template match="/">
                                <delegation:execute service="image-server" operation="uploadImage">
                                    <name><xsl:value-of select="/*/file/@filename"/></name>
                                    <file><xsl:value-of select="/*/*[1]"/></file>
                                </delegation:execute>
                            </xsl:template>
                        </xsl:stylesheet>
                    </p:input>
                    <p:output name="data" id="call"/>
                </p:processor>

                <!-- Call the Web service using the Delegation processor -->
                <p:processor name="oxf:delegation">
                    <p:input name="interface">
                        <config>
                            <service id="image-server" type="webservice"
                                endpoint="http://www.scdi.org/~avernet/webservice/">
                                <operation nsuri="urn:avernet" name="uploadImage"/>
                            </service>
                        </config>
                    </p:input>
                    <p:input name="data"><dummy/></p:input>
                    <p:input name="call" href="#call"/>
                    <p:output name="data" ref="data"/>
                </p:processor>

            </p:when>
            <p:otherwise>
                <!-- Return empty URL -->
                <p:processor name="oxf:identity">
                    <p:input name="data"><url/></p:input>
                    <p:output name="data" ref="data"/>
                </p:processor>
            </p:otherwise>
        </p:choose>
    </p:for-each>

</p:config>
