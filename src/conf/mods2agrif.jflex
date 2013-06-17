package gr.agroknow.metadata.transformer.mods2agrif;

import gr.agroknow.metadata.agrif.Agrif;
import gr.agroknow.metadata.agrif.Citation;
import gr.agroknow.metadata.agrif.ControlledBlock;
import gr.agroknow.metadata.agrif.Creator;
import gr.agroknow.metadata.agrif.Expression;
import gr.agroknow.metadata.agrif.Item;
import gr.agroknow.metadata.agrif.LanguageBlock;
import gr.agroknow.metadata.agrif.Manifestation;
import gr.agroknow.metadata.agrif.Relation;
import gr.agroknow.metadata.agrif.Rights;
import gr.agroknow.metadata.agrif.Publisher;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.List;
import java.util.ArrayList;

import net.zettadata.generator.tools.Toolbox;
import net.zettadata.generator.tools.ToolboxException;

%%
%class MODS2AGRIF
%standalone
%unicode

%{
	// AGRIF
	private List<Agrif> agrifs ;
	private Agrif agrif ;
	private Citation citation ;
	private ControlledBlock cblock ;
	private Creator creator ;
	private Expression expression ;
	private Item item ;
	private LanguageBlock lblock ;
	private Manifestation manifestation ;
	private Relation relation ;
	private Rights rights ;
	private Publisher publisher ;
	
	// TMP
	private StringBuilder tmp ;
	private String language ;
	private String thesaurus ;
	private String classification ;
	private Item tmpItem ;
	private Manifestation tmpManifestation ;
	private String authority ;
	
	// OTHER
	private String modsVersion = "mods" ;
	private boolean ignoretext ;
	private String citationNumber ;
	private String citationChronology ;
	private String citationPages ;
	
	// EXERNAL
	private String potentialLanguages ;
	private String mtdLanguage ;
	private String providerId ;
	private String manifestationType = "landingPage" ;
	
	public void setPotentialLanguages( String potentialLanguages )
	{
		this.potentialLanguages = potentialLanguages ;
	}
	
	public void setMtdLanguage( String mtdLanguage )
	{
		this.mtdLanguage = mtdLanguage ;
	}
	
	public void setManifestationType( String manifestationType )
	{
		this.manifestationType = manifestationType ;
	}
	
	public void setProviderId( String providerId )
	{
		this.providerId = providerId ;
	}
	
	public List<Agrif> getAgrifs()
	{
		return agrifs ;
	}
	
	private void init()
	{
		agrif = new Agrif() ;
		agrif.setSet( providerId ) ;
		citation  = new Citation() ;
		cblock = new ControlledBlock() ;
		expression = new Expression() ;
		lblock = new LanguageBlock() ;
		relation = new Relation() ;
		rights = new Rights() ;
		// tmp elements
		tmpItem = null ;
		tmpManifestation = null ;
		ignoretext = false ;
	}
	
	private String utcNow() 
	{
		Calendar cal = Calendar.getInstance();
		SimpleDateFormat sdf = new SimpleDateFormat( "yyyy-MM-dd" );
		return sdf.format(cal.getTime());
	}
	
	private String extract( String element )
	{	
		return element.substring(element.indexOf(">") + 1 , element.indexOf("</") );
	}
	
%}

%state RESOURCES
%state AGRIF
%state TITLEINFO
%state LTITLEINFO
%state LANGUAGE
%state ISO6392
%state L6392
%state ISO6391
%state L6391
%state LOCATION
%state LABSTRACT
%state ABSTRACT
%state SUBJECT
%state THESAURUS
%state DESCRIPTOR
%state PHYSICAL
%state ORIGIN
%state GENREAUTHORITY
%state GENRE
%state CITATION
%state PART
%state VOLUME
%state ISSUE
%state PAGE
%state CREATOR
%state RIGHTS
%state CLASSIFICATION
%state CLASSENTRY

%%

<YYINITIAL>
{
	"<modsCollection"|"<mods:modsCollection"
	{
		yybegin( RESOURCES ) ;
		agrifs = new ArrayList<Agrif>() ;
	}
	
	"<mods"|"<mods:mods"
	{
		agrifs = new ArrayList<Agrif>() ;
		init() ;
		yybegin( AGRIF ) ;
	}
}

<RESOURCES>
{
	"</modsCollection>"|"</mods:modsCollection>"
	{
		yybegin( YYINITIAL ) ;
	}
	
	"<mods"|"<mods:mods"
	{
		init() ;
		yybegin( AGRIF ) ; 
	}
}

<AGRIF>
{
	"</mods>"|"</mods:mods>"
	{
		if ( !expression.toJSONObject().containsKey( "manifestations" ) )
		{
			if ( tmpManifestation == null )
			{
				// abort 
			}
			else
			{
				expression.setManifestation( tmpManifestation ) ;
			}
		} 
		agrif.setExpression( expression ) ;
		agrif.setLanguageBlocks( lblock ) ;
		agrif.setControlled( cblock ) ;
		agrifs.add( agrif ) ;
		yybegin( RESOURCES ) ;
	}
	
	"<titleInfo>"|"<mods:titleInfo>"
	{
		yybegin( TITLEINFO ) ;
		tmp = new StringBuilder() ;
		language = null ;
	}
	
	"<titleInfo xml:lang=\""|"<mods:titleInfo xml:lang=\""
	{
		yybegin( LTITLEINFO ) ;
		tmp = new StringBuilder() ;
	}
	
	"<titleInfo lang=\""|"<mods:titleInfo lang=\""
	{
		yybegin( LTITLEINFO ) ;
		tmp = new StringBuilder() ;
	}
	
	"<titleInfo".+">"|"<mods:titleInfo".+">"
	{
		yybegin( TITLEINFO ) ;
		tmp = new StringBuilder() ;
		language = null ;
	}
		
	"<language>"|"<mods:language>"|"<language".+"\">"|"<mods:language".+"\">"
	{
		yybegin( LANGUAGE ) ;
	}
	
	"<identifier type=\"uri\">http://".+"</identifier>"|"<mods:identifier type=\"uri\">http://".+"</mods:identifier>"
	{
		tmpItem = new Item() ;
		tmpItem.setDigitalItem( extract( yytext() ) ) ;
		if ( tmpManifestation == null )
		{
			tmpManifestation = new Manifestation() ;
		}
		tmpManifestation.setItem( tmpItem ) ;
		tmpManifestation.setManifestationType( manifestationType ) ;
		yybegin( AGRIF ) ;
	}
	
	"<location>"|"<mods:location>"
	{
		yybegin( LOCATION ) ;
	}
	
	"<abstract xml:lang=\""|"<mods:abstract xml:lang=\""
	{
		yybegin( LABSTRACT ) ;
		tmp = new StringBuilder() ;
	}
	
	"<abstract>"|"<mods:abstract>"
	{
		language = null ; 
		yybegin( ABSTRACT ) ;
		tmp = new StringBuilder() ;
	}
	
	"<note type=\"status\">".+"</note>"|"<mods:note type=\"status\">".+"</mods:note>"
	{
		expression.setPublicationStatus( modsVersion, extract( yytext() ) ) ;
	}

    "<note type=\"review\">".+"</note>"|"<mods:note type=\"review\">".+"</mods:note>"
    {
    	cblock.setReviewStatus( modsVersion, extract( yytext() ) ) ;
    }
    
    "<subject>"|"<mods:subject>"
    {
    	yybegin( SUBJECT ) ;
    }
    
    "<subject authority=\""|"<mods:subject authority=\""
    {
    	yybegin( THESAURUS ) ;
    	tmp = new StringBuilder() ;
    }
    
    "<physicalDescription>"|"<mods:physicalDescription>"
    {
    	yybegin( PHYSICAL ) ;
    }
    
    "<originInfo>"|"<mods:originInfo>"
    {
    	yybegin( ORIGIN ) ;
    	publisher = new Publisher() ;
    }
    
    "<genre>".+"</genre>"|"<mods:genre>".+"</mods:genre>"
    {
    	String genre = extract( yytext() ) ;
    	cblock.setType( modsVersion, genre ) ;
    	String type =  Singleton.getInstance().getManifestationType( genre ) ;
    	if ( type != null )
    	{
    		if ( tmpManifestation == null )
    		{
    			tmpManifestation = new Manifestation() ;
    		}
    		tmpManifestation.setManifestationType( type ) ;
    	}
    	String status = Singleton.getInstance().getPublicationStatus( genre ) ;
    	if ( status != null )
    	{
    		expression.setPublicationStatus( modsVersion, status ) ;
    	}
    }
    
    "<genre".+"authority=\""|"<mods:genre".+"authority=\""
    {
    	yybegin( GENREAUTHORITY ) ;
    	tmp = new StringBuilder() ;
    }
    
    "<relatedItem type=\"host\">"|"<mods:relatedItem type=\"host\">"
    {
    	yybegin( CITATION ) ;
    	citation = new Citation() ;
    	
    }
    
    "<name type=\"personal\">"|"<mods:name type=\"personal\">"|"<name type=\"personal\"".+">"|"<mods:name type=\"personal\"".+">"
    {
    	yybegin( CREATOR ) ;
    	creator = new Creator() ;
    	creator.setType( "person" ) ;
    	tmp = new StringBuilder() ;
    }
    
    "<accessCondition".+">http://".+"</accessCondition>"|"<mods:accessCondition".+">http://".+"</mods:accessCondition>"
    {
    	rights = new Rights() ;
    	rights.setIdentifier( extract( yytext() ) ) ;
    	agrif.setRights( rights) ;
    }
    
    "<accessCondition".+"</accessCondition>"|"<mods:accessCondition".+"</mods:accessCondition>"
    {
    	rights = new Rights() ;
    	String r = extract( yytext() ) ;
    	if ( mtdLanguage != null )
		{
			rights.setTermsOfUse( mtdLanguage, r ) ;
		}
		else if ( potentialLanguages == null )
		{
			try
			{
				rights.setTermsOfUse( Toolbox.getInstance().detectLanguage( r ), r ) ;
			}
				catch ( ToolboxException te){}
		}
		else
		{
			try
			{
				rights.setTermsOfUse( Toolbox.getInstance().detectLanguage( r, potentialLanguages ) , r ) ;
			}
			catch ( ToolboxException te){}		
		}
    	agrif.setRights( rights) ;
    }
    
      "<classification authority=\""|"<mods:classification authority=\""
      {
      	tmp = new StringBuilder() ;
      	yybegin( CLASSIFICATION ) ;
      }

}

<CLASSIFICATION>
{
	"\">"
	{
		thesaurus = tmp.toString() ;
		yybegin( CLASSENTRY ) ;
		tmp = new StringBuilder() ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<CLASSENTRY>
{
	"</classification>"|"</mods:classification>"
	{
		cblock.setDescriptor( thesaurus, tmp.toString() ) ;
		yybegin( AGRIF ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}


<CREATOR>
{
	"</name>"|"</mods:name>"
	{
		yybegin( AGRIF ) ;
		if ( tmp.length() != 0 )
		{
			creator.setName( tmp.toString().trim() ) ;
		}
		agrif.setCreator( creator ) ;
	}
	
	"<namePart>".+"</namePart>"|"<mods:namePart>".+"</mods:namePart>"
	{
		creator.setName( extract( yytext() ) ) ;
	}
	
    "<mods:namePart type=\"family\">".+"</mods:namePart>"
    {
    	tmp.append( " " + extract( yytext() ) ) ;
    }
    
    "<mods:namePart type=\"given\">".+"</mods:namePart>"
	{
		if ( tmp.length() == 0 )
		{
			tmp.append( extract( yytext() ) ) ;
		}
		else
		{
			tmp.append( ", " + extract( yytext() ) ) ;
		}
	}
	
}

<CITATION>
{
	"</relatedItem>"|"</mods:relatedItem>"
	{
		expression.setCitation( citation ) ; 
		yybegin( AGRIF ) ;
	}
	
	"<title>".+"</title>"|"<mods:title>".+"</mods:title>"
	{
		ignoretext = true ;
		citation.setTitle( extract( yytext() ) ) ;
	}
	
	"<text>".+"</text>"|"<mods:text>".+"</mods:text>"
	{
		if ( !ignoretext )
		{
			citation.setTitle( extract( yytext() ) ) ;
			ignoretext = true ;
		}
	}	
	
	"<part>"|"<mods:part>"
	{
		yybegin( PART ) ;
	}
	
    "<mods:identifier type=\"isbn\">".+"</identifier>"|"<mods:identifier type=\"isbn\">".+"</mods:identifier>"
    {
    	citation.setIdentifier( "isbn", extract( yytext() ) ) ;
    }

    "<mods:identifier type=\"issn\">".+"</identifier>"|"<mods:identifier type=\"issn\">".+"</mods:identifier>"
    {
    	citation.setIdentifier( "issn", extract( yytext() ) ) ;
    }
    
    "<mods:identifier type=\"doi\">".+"</identifier>"|"<mods:identifier type=\"doi\">".+"</mods:identifier>"
    {
    	citation.setIdentifier( "doi", extract( yytext() ) ) ;
    }
		
}

<PART>
{
	"</part>"|"</mods:part>"
	{
		yybegin( CITATION ) ;
		if ( citationNumber != null )
		{
			citation.setCitationNumber( citationNumber.trim() ) ;
		}
		if ( citationChronology != null )
		{
			citation.setCitationChronology( citationChronology.trim() ) ;
		}
	}
	
	
	"<text>".+"</text>"|"<mods:text>".+"</mods:text>"
	{
		if ( !ignoretext )
		{
			citation.setTitle( extract( yytext() ) ) ;
		}
	}	
	
	
	"<detail unit=\"volume\">"|"<mods:detail unit=\"volume\">"|"<detail type=\"volume\">"|"<mods:detail type=\"volume\">"
	{
		yybegin( VOLUME ) ;
	}
	
	"<detail unit=\"issue\">"|"<mods:detail unit=\"issue\">"|"<detail type=\"issue\">"|"<mods:detail type=\"issue\">"
	{
		yybegin( ISSUE ) ;
	}
	
	"<extent unit=\"page\">"|"<mods:extent unit=\"page\">"|"<extent type=\"page\">"|"<mods:extent type=\"page\">"
	{
		yybegin( PAGE ) ;
		citationChronology = null ;
	}

}

<VOLUME>
{
	"</detail>"|"</mods:detail>"
	{
		yybegin( PART ) ;
	}
	
	"<number>".+"</number>"|"<mods:number>".+"</mods:number>"
	{
		citationNumber = "volume " + extract( yytext() ) + " " ;
	}
}

<ISSUE>
{
	"</detail>"|"</mods:detail>"
	{
		yybegin( PART ) ;
	}
	
	"<number>".+"</number>"|"<mods:number>".+"</mods:number>"
	{
		citationNumber = citationNumber + "issue " + extract( yytext() ) ;
	}
}   
      
<PAGE>
{
	"</extent>"|"</mods:extent>"|"</extent>"|"</mods:extent>"
	{
		yybegin( PART ) ; // citationPages
	}
	
	"<start>".+"</start>"|"<mods:start>".+"</mods:start>"
	{
		citationChronology = extract( yytext() ) ;
	}
	
	"<end>".+"</end>"|"<mods:end>".+"</mods:end>"
	{
		if ( citationChronology == null )
		{
			citationChronology = extract( yytext() ) ;
		}
		else
		{
			citationChronology = citationChronology + " - " + extract( yytext() ) ;
		}
	}
	
}
      
<GENREAUTHORITY>
{
	"\">"
	{
		authority = tmp.toString() ;
		yybegin( GENRE ) ;
		tmp = new StringBuilder() ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<GENRE>
{
	"</genre>"|"</mods:genre>"
	{
		String genre = tmp.toString().toLowerCase() ;
		if ( !"[null]".equals( genre ) )
		{
			cblock.setType( authority, genre ) ;
    		String type =  Singleton.getInstance().getManifestationType( genre ) ;
    		if ( type != null )
    		{
    			if ( tmpManifestation == null )
    			{
    				tmpManifestation = new Manifestation() ;
    			}
    			tmpManifestation.setManifestationType( type ) ;
    		}
    		String status = Singleton.getInstance().getPublicationStatus( genre ) ;
    		if ( status != null )
    		{
    			expression.setPublicationStatus( modsVersion, status ) ;
    		}
    	}
		yybegin( AGRIF ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<THESAURUS>
{
	"\"".+"URI=\""|"\"".+"\n".+"URI=\""
	{
		thesaurus = tmp.toString() ;
		yybegin( DESCRIPTOR ) ;
		tmp = new StringBuilder() ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<ORIGIN>
{
	"</originInfo>"|"</mods:originInfo>"
	{
		yybegin( AGRIF ) ;
		expression.setPublisher( publisher ) ;
	}
	
	"<publisher>".+"</publisher>"|"<mods:publisher>".+"</mods:publisher>"
	{
		publisher.setName( extract(  yytext() ) ) ;
	}
	
	"<dateIssued encoding=\"iso8601\">".+"</dateIssued>"|"<mods:dateIssued encoding=\"iso8601\">".+"</mods:dateIssued>"
	{
		publisher.setDate( extract( yytext() ) ) ;
	}
	
	"<dateIssued>".+"</dateIssued>"|"<mods:dateIssued>".+"</mods:dateIssued>"
	{
		publisher.setDate( extract( yytext() ) ) ;
	}
}

<PHYSICAL>
{
	"</physicalDescription>"|"</mods:physicalDescription>"
	{
		yybegin( AGRIF ) ;
	}

    "<internetMediaType>".+"</internetMediaType>"|"<mods:internetMediaType>".+"</mods:internetMediaType>"
    {
    	if ( tmpManifestation == null )
    	{
    		tmpManifestation = new Manifestation() ;
    	}
    	tmpManifestation.setFormat( extract( yytext() ) ) ;
    }
    
    "<extent>".+"</extent>"|"<mods:extent>".+"</mods:extent>"
    {
    	if ( tmpManifestation == null )
    	{
    		tmpManifestation = new Manifestation() ;
    	}
    	tmpManifestation.setSize( extract( yytext() ) ) ;
    }
    
}

<DESCRIPTOR>
{
	"\">"
	{
		cblock.setDescriptor( thesaurus, tmp.toString() ) ;
		yybegin( AGRIF ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<SUBJECT>
{
	"</subject>"|"</mods:subject>"
	{
		yybegin( AGRIF ) ;
	}
	
	"<geographic>".+"</geographic>"|"<mods:geographic>".+"</mods:geographic>"
	{
		cblock.setSpatialCoverage( modsVersion, extract(  yytext() ) ) ;
	}
	
    "<topic>".+"</topic>"|"<mods:topic>".+"</mods:topic>"
    {
    	String tmpk = extract( yytext() ) ;
		if ( mtdLanguage != null )
		{
			lblock.setKeyword( mtdLanguage, tmpk ) ;
		}
		else if ( potentialLanguages == null )
		{
			try
			{
				lblock.setKeyword( Toolbox.getInstance().detectLanguage( tmpk ) , tmpk ) ;
			}
			catch ( ToolboxException te){}
		}
		else
		{
			try
			{
				lblock.setKeyword( Toolbox.getInstance().detectLanguage( tmpk, potentialLanguages ) , tmpk ) ;
			}
			catch ( ToolboxException te){}
		}
    }
	
}


<LABSTRACT>
{
	"\">"
	{
		language = tmp.toString() ;
		if ( language.length() == 3 )
		{
			try
			{
				language = Toolbox.getInstance().toISO6391( language ) ;
			}
			catch( ToolboxException te ) {}
		}
		yybegin( ABSTRACT ) ;
		tmp = new StringBuilder() ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<ABSTRACT>
{
	"</abstract>"|"</mods:abstract>"
	{
		yybegin( AGRIF ) ;
		String tmptitle = tmp.toString() ;
		if ( language != null )
		{
			lblock.setAbstract( language, tmptitle ) ;
		}
		else if ( mtdLanguage != null )
		{
			lblock.setAbstract( mtdLanguage, tmptitle ) ;
		}
		else
		{
			if ( potentialLanguages == null )
			{
				try
				{
					lblock.setAbstract( Toolbox.getInstance().detectLanguage( tmptitle ) , tmptitle ) ;
				}
				catch ( ToolboxException te){}
			}
			else
			{
				try
				{
					lblock.setAbstract( Toolbox.getInstance().detectLanguage( tmptitle, potentialLanguages ) , tmptitle ) ;
				}
				catch ( ToolboxException te){}
			}		
		}
	}
	
	.|\n
	{
		tmp.append( yytext() ) ;
	}
}


<LOCATION>
{
	"</location>"|"</mods:location>"
	{
		yybegin( AGRIF ) ;
	}
	
	"<url".+"access=\"object in context\">".+"</url>"|"<mods:url".+"access=\"object in context\">".+"</mods:url>"
	{
		item = new Item() ;
		item.setDigitalItem( extract( yytext() ) ) ;
		manifestation = new Manifestation() ;
		manifestation.setItem( item ) ;
		manifestation.setManifestationType( "landingPage" ) ;
		expression.setManifestation( manifestation ) ;
	}
	
	"<url".+"access=\"raw object\">".+"</url>"|"<mods:url".+"access=\"raw object\">".+"</mods:url>"
	{
		item = new Item() ;
		item.setDigitalItem( extract( yytext() ) ) ;
		manifestation = new Manifestation() ;
		manifestation.setItem( item ) ;
		manifestation.setManifestationType( "fullText" ) ;
		expression.setManifestation( manifestation ) ;
	}
	
	"<url displayLabel=\"electronic resource\" usage=\"primary display\">".+"</url>"|"<mods:url displayLabel=\"electronic resource\" usage=\"primary display\">".+"</mods:url>"
	{
		item = new Item() ;
		item.setDigitalItem( extract( yytext() ) ) ;
		manifestation = new Manifestation() ;
		manifestation.setItem( item ) ;
		manifestation.setManifestationType( "fullText" ) ;
		expression.setManifestation( manifestation ) ;	
	}
	
	
}

<LANGUAGE>
{
	"</language>"|"</mods:language>"
	{
		yybegin( AGRIF ) ;
	}

	"<languageTerm".+"authority=\"iso639-1"|"<mods:languageTerm".+"authority=\"iso639-1"
	{
		yybegin( ISO6391 ) ;
	}
	
	"<languageTerm".+"authority=\"rfc3066"|"<mods:languageTerm".+"authority=\"rfc3066"
	{
		yybegin( ISO6391 ) ;
	}
    
	"<languageTerm".+"authority=\"iso639-2"|"<mods:languageTerm".+"authority=\"iso639-2"
	{
		yybegin( ISO6392 ) ;
	}
	
	

}

<ISO6392>
{
	"\">"
	{
		tmp = new StringBuilder() ;
		yybegin( L6392 ) ;
	}

	.|\n {}
}

<L6392>
{
	"</languageTerm>"|"</mods:languageTerm>"
	{
		try
		{
			expression.setLanguage( Toolbox.getInstance().toISO6391( tmp.toString() ) ) ;
		}
		catch( ToolboxException te ) {}
		yybegin( LANGUAGE ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<ISO6391>
{
	"\">"
	{
		tmp = new StringBuilder() ;
		yybegin( L6391 ) ;
	}

	.|\n {}
}

<L6391>
{
	"</languageTerm>"|"</mods:languageTerm>"
	{
		expression.setLanguage( tmp.toString() ) ;
		yybegin( LANGUAGE ) ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}

<LTITLEINFO>
{
	"\">"|"\"".+">"
	{
		language = tmp.toString() ;
		if ( language.length() == 3 )
		{
			try
			{
				language = Toolbox.getInstance().toISO6391( language ) ;
			}
			catch( ToolboxException te ) {}
		}
		yybegin( TITLEINFO ) ;
		tmp = new StringBuilder() ;
	}
	
	.
	{
		tmp.append( yytext() ) ;
	}
}	
	
<TITLEINFO>
{
	"</titleInfo>"|"</mods:titleInfo>"
	{
		yybegin( AGRIF ) ;
	}

	"<title>".+"</title>"|"<mods:title>".+"</mods:title>"
	{
		String tmptitle = extract( yytext() ) ;
		
		if ( language != null )
		{
			if ( lblock.hasTitle( language ) )
			{
				lblock.setAlternativeTitle( language, tmptitle ) ;
			}
			else
			{
				lblock.setTitle( language, tmptitle ) ;
			}
		}
		else if ( mtdLanguage != null )
		{
			if ( lblock.hasTitle( mtdLanguage ) )
			{
				lblock.setAlternativeTitle( language, tmptitle ) ;
			}
			else
			{
				lblock.setTitle( mtdLanguage, tmptitle ) ;
			}
		}
		else
		{
			if ( potentialLanguages == null )
			{
				if ( lblock.hasTitle( mtdLanguage ) )
				{
					try
					{
						lblock.setAlternativeTitle( Toolbox.getInstance().detectLanguage( tmptitle ) , tmptitle ) ;
					}
					catch ( ToolboxException te){}
				}
				else
				{
					try
					{
						lblock.setTitle( Toolbox.getInstance().detectLanguage( tmptitle ) , tmptitle ) ;
					}
					catch ( ToolboxException te){}
				}
			}
			else
			{
				if ( lblock.hasTitle( mtdLanguage ) )
				{
					try
					{
						lblock.setAlternativeTitle( Toolbox.getInstance().detectLanguage( tmptitle, potentialLanguages ) , tmptitle ) ;
					}
					catch ( ToolboxException te){}
				}
				else
				{
					try
					{
						lblock.setTitle( Toolbox.getInstance().detectLanguage( tmptitle, potentialLanguages ) , tmptitle ) ;
					}
					catch ( ToolboxException te){}
				}
			}		
		}
	}

	"<subTitle>".+"</subTitle>"|"<mods:subTitle>".+"</mods:subTitle>"
	{
		String tmptitle = extract( yytext() ) ;
		if ( language != null )
		{
			lblock.setTitleSupplemental( language, tmptitle ) ;
		}
		else if ( mtdLanguage != null )
		{
			lblock.setTitleSupplemental( mtdLanguage, tmptitle ) ;
		}
		else
		{
			if ( potentialLanguages == null )
			{
				try
				{
					lblock.setTitleSupplemental( Toolbox.getInstance().detectLanguage( tmptitle ) , tmptitle ) ;
				}
				catch ( ToolboxException te){}
			}
			else
			{
				try
				{
					lblock.setTitleSupplemental( Toolbox.getInstance().detectLanguage( tmptitle, potentialLanguages ) , tmptitle ) ;
				}
				catch ( ToolboxException te){}
			}		
		}
	}
}
	
	
/* error fallback */
.|\n 
{
	//throw new Error("Illegal character <"+ yytext()+">") ;
}