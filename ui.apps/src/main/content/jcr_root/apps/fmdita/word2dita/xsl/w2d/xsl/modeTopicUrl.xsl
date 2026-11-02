<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      xmlns:local="urn:local-functions"
      xmlns:rsiwp="http://reallysi.com/namespaces/generic-wordprocessing-xml"
      xmlns:stylemap="urn:public:dita4publishers.org:namespaces:word2dita:style2tagmap"
      xmlns:relpath="http://dita2indesign/functions/relpath"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:m="http://www.w3.org/1998/Math/MathML"
      
      exclude-result-prefixes="xs rsiwp stylemap local relpath xsi"
  version="2.0">
  <!-- =========================================
       Word to DITA Framework
       
       Copyright (c) 2014 DITA for Publishers
       
       Base implementation for the "topic-url" mode,
       which constructs the result URLs for 
       generated topics.
       
       Override these templates to implement your
       own map filenaming conventions.
       ========================================= -->
  
  <!-- The default number format to use for generating topic numbers. -->
  <xsl:param name="topicNumberFormat" as="xs:string" select="'_1_1'"/>
  
  <xsl:template match="rsiwp:topic" mode="topic-url">   
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="topicrefType" as="xs:string"/>
    <xsl:param name="topicName" as="xs:string"/>
    
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] rsiwp:topic, mode=topic-url: topicName=<xsl:sequence select="$topicName"/></xsl:message>
    </xsl:if>

    <xsl:variable name="finalTopicName" as="xs:string">
      <xsl:choose>
        <xsl:when test="$topicName = ''">
          <xsl:apply-templates mode="topic-name" select="."/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$topicName"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] rsiwp:topic, mode=topic-url: finalTopicName=<xsl:sequence select="$finalTopicName"/></xsl:message>
    </xsl:if>
    
    <xsl:variable name="result" select="concat('topics/', $topicName, $topicExtension)"/>
    <xsl:if test="$doDebug">
      <xsl:message> + [DEBUG] rsiwp:topic, mode=topic-url: result="<xsl:sequence select="$result"/>"</xsl:message>
    </xsl:if>
    <xsl:sequence select="$result"/>
  </xsl:template>
  
  <xsl:template match="rsiwp:topic" mode="topic-name">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:param name="topicTitleListStr" as="xs:string" select="''"/>

	<xsl:if test="$doDebug">
		<xsl:message> + [DEBUG] rsiwp:topic: All topic titles, to be used to check duplicates="<xsl:value-of select="$topicTitleListStr"/>"</xsl:message>
    </xsl:if>

    <!-- Generates the name for a topic, which can then be
         used in IDs and filenames.
      -->
    <xsl:variable name="treePosString" as="xs:string">
      <!-- This numbering numbers the topics sequentially through the map
        
           - The root topic (if there is no map)
           - Each topicref
           - Each non-document-root topic           

      -->
      <xsl:number count="
        rsiwp:topicref |
        rsiwp:body/rsiwp:topic |
        rsiwp:topic[parent::rsiwp:topic]" format="{$topicNumberFormat}"
        from="/"
        level="any"
      />
    </xsl:variable>
    
    <xsl:variable name="result" select="concat($fileNamePrefix, 'topic', string-join($treePosString, ''))"/>
	<!-- DXML3726: Update topic name to be be AEM compliant: lowercase, spaces replaced with hyphen and remove special characters -->
    <xsl:variable name="nameFromTitle" select="replace(replace(normalize-space(lower-case((./rsiwp:p[@tagName='title'])[1])), ' ', '-'), '[^a-zA-Z0-9_-]', '')"/>


	<!-- DXML-3726: Check if the topic title occurs more than once, if so the duplicateTitlecount will help decide in creating file using topic name and topic position -->
	<xsl:variable name="topicTitleOriginal" select="replace(replace(normalize-space(lower-case(concat((./rsiwp:p[@tagName='title'])[1],'||'))), ' ', '-'), '[^a-zA-Z0-9_-||]', '')"/>
	<xsl:variable name="duplicateTitlecount">
        <xsl:call-template name="substring-count">
            <xsl:with-param name="string" select="substring-after(replace(replace(normalize-space(lower-case($topicTitleListStr)), ' ', '-'), '[^a-zA-Z0-9_-||]', ''), $topicTitleOriginal)"/>
            <xsl:with-param name="substr" select="$topicTitleOriginal"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$doDebug">
		<xsl:message> + [DEBUG] rswip:topic: Topic Title="<xsl:value-of select="(./rsiwp:p[@tagName='title'])[1]"/>" | Duplicacy Count="<xsl:value-of select="$duplicateTitlecount"/>"</xsl:message>
	</xsl:if>

    <xsl:choose>
    <xsl:when test="$nameFromTitle">
		<xsl:choose>
    	<xsl:when test="number($duplicateTitlecount) &gt; 0">
        	<xsl:if test="$doDebug">
                <xsl:message> + [DEBUG] rswip:topic: Topic Title is duplicate append position to filename="<xsl:value-of select="concat($nameFromTitle, $treePosString)"/>"</xsl:message>
            </xsl:if>
    		<xsl:sequence select="concat($nameFromTitle, $treePosString)"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:sequence select="$nameFromTitle"/>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
   		<xsl:sequence select="$result"/>
    </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>    

  <xsl:template match="text()" mode="topic-url"/>   
  
 
  <xsl:template match="rsiwp:*" mode="topic-url">
    <xsl:param name="doDebug" as="xs:boolean" tunnel="yes" select="false()"/>
    <xsl:message> - [WARNING] Unhandled element <xsl:sequence select="name(..)"/>/<xsl:sequence select="name(.)"/> in mode 'topic-url'</xsl:message>
    <xsl:variable name="topicTitleFragment">
      <xsl:choose>
        <xsl:when test="contains(.,' ')">
          <xsl:value-of select="replace(substring-before(.,' '),'[\p{P}\p{Z}\p{C}]','')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="replace(.,'[\p{P}\p{Z}\p{C}]','')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="concat('topics/topic_', $topicTitleFragment, '_', generate-id(.),format-time(current-time(),'[h][m][s]'), '.dita')"/>
  </xsl:template>

	<!-- DXML-3726: add method to find substring occurences -->
    <xsl:template name="substring-count">
        <xsl:param name="string"/>
        <xsl:param name="substr"/>

        <xsl:choose>
        <xsl:when test="contains($string, $substr) and $string and $substr">
            <xsl:variable name="countOccurences">
                <xsl:call-template name="substring-count">
                    <xsl:with-param name="string" select="substring-after($string, $substr)"/>
                    <xsl:with-param name="substr" select="$substr"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="$countOccurences + 1"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
  
</xsl:stylesheet>