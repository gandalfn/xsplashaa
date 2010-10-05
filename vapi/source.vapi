namespace XSAA
{
    [CCode (cheader_filename = "xsaa-source.h", ref_function = "xsaa_source_ref", unref_function = "xsaa_source_unref")]
    public class Source : GLib.Source
    {
        public Source(SourceFuncs inFuncs, void* inData);
        public Source.from_pollfd(SourceFuncs inFuncs, GLib.PollFD inFd, void* inData);
        public Source @ref();
        public void unref();
        public void destroy();
    }

    [CCode (cheader_filename = "xsaa-source.h", has_target = false)]
    public delegate bool SourcePrepareFunc (void* inData, out int outTimeout);
    [CCode (cheader_filename = "xsaa-source.h", has_target = false)]
    public delegate bool SourceCheckFunc (void* inData);
    [CCode (cheader_filename = "xsaa-source.h", has_target = false)]
    public delegate bool SourceDispatchFunc (void* inData, GLib.SourceFunc inCallback);
    [CCode (cheader_filename = "xsaa-source.h", has_target = false)]
    public delegate void SourceFinalizeFunc (void* inData);

    [SimpleType]
    [CCode (cheader_filename = "xsaa-source.h")]
    public struct SourceFuncs 
    {
        public SourcePrepareFunc prepare;
        public SourceCheckFunc check;
        public SourceDispatchFunc dispatch;
        public SourceFinalizeFunc finalize;
    }
} 
