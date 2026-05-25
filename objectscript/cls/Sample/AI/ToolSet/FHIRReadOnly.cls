/// Read-only FHIR toolset.
///
/// Includes only Search* and Get* methods from Sample.AI.Tools.FHIRReadOnly.
/// This keeps the default surface safe for analytics and exploration workflows.
Class Sample.AI.ToolSet.FHIRReadOnly Extends %AI.ToolSet
    [ DependsOn = Sample.AI.Tools.FHIRReadOnly ]
{

XData Definition [ MimeType = application/xml ]
{
  <ToolSet Name="FHIRReadOnly">
    <Description>
      Read-only access to FHIR resources (Patient, Observation, AllergyIntolerance)
      for AI-assisted interoperability analysis and smart patient summaries.
    </Description>

    <Policies>
      <Audit Class="%AI.Policy.ConsoleAudit"/>
    </Policies>

    <Include Class="Sample.AI.Tools.FHIRReadOnly" Match="^(Search|Get|Generate)"/>
  </ToolSet>
}

}